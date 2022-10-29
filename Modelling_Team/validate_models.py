import logging

logging.basicConfig(format="%(levelname)s - %(name)s -  %(message)s", level=logging.WARNING)
logging.getLogger("haystack").setLevel(logging.INFO)


import os
from haystack.document_stores import ElasticsearchDocumentStore

# make sure these indices do not collide with existing ones, the indices will be wiped clean before data is inserted
doc_index = "val_docs"
label_index = "val_labels"

# Get the host where Elasticsearch is running, default to localhost
host = os.environ.get("ELASTICSEARCH_HOST", "localhost")

# Connect to Elasticsearch
document_store = ElasticsearchDocumentStore(
    host=host,
    username="",
    password="",
    index=doc_index,
    label_index=label_index,
    embedding_field="emb",
    embedding_dim=768,
    excluded_meta_data=["emb"],
)



from haystack.nodes import PreProcessor

preprocessor = PreProcessor(
    split_by="word",
    split_length=200,
    split_overlap=0,
    split_respect_sentence_boundary=False,
    clean_empty_lines=False,
    clean_whitespace=False,
)
document_store.delete_documents(index=doc_index)
document_store.delete_documents(index=label_index)

# The add_eval_data() method converts the given dataset in json format into Haystack document and label objects. Those objects are then indexed in their respective document and label index in the document store. The method can be used with any dataset in SQuAD format.
document_store.add_eval_data(
    filename="Annotation/Labels/answers.json",
    doc_index=doc_index,
    label_index=label_index,
    preprocessor=preprocessor,
)






from haystack.nodes import BM25Retriever

retriever = BM25Retriever(document_store=document_store)


from haystack.nodes import FARMReader

reader = FARMReader("deepset/bert-large-uncased-whole-word-masking-squad2",use_gpu=True, top_k=5, return_no_answer=True)


from haystack.pipelines import ExtractiveQAPipeline

pipeline = ExtractiveQAPipeline(reader=reader, retriever=retriever)




# We can load evaluation labels from the document store
# We are also opting to filter out no_answer samples
eval_labels = document_store.get_all_labels_aggregated(drop_negative_labels=True, drop_no_answers=True)


from haystack.schema import EvaluationResult, MultiLabel

advanced_eval_result = pipeline.eval(
    labels=eval_labels, params={"Retriever": {"top_k": 5}}, sas_model_name_or_path="cross-encoder/stsb-roberta-large"
)

metrics = advanced_eval_result.calculate_metrics()
print(metrics["Reader"]["sas"])