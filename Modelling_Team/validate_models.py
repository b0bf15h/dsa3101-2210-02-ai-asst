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
        clean_empty_lines=True,
        clean_whitespace=True,
        clean_header_footer=False,
        split_by="word",
        split_length=200,
        split_overlap=0,
        split_respect_sentence_boundary=False,
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

reader = FARMReader("deepset/roberta-base-squad2", top_k=5, return_no_answer=True)


from haystack.pipelines import ExtractiveQAPipeline

pipeline = ExtractiveQAPipeline(reader=reader, retriever=retriever)




# We can load evaluation labels from the document store
# We are also opting to filter out no_answer samples
eval_labels = document_store.get_all_labels_aggregated(drop_negative_labels=True, drop_no_answers=True)

# Similar to pipeline.run() we can execute pipeline.eval()
eval_result = pipeline.eval(labels=eval_labels, params={"Retriever": {"top_k": 5}})

retriever_result = eval_result["Retriever"]
retriever_result.head()

reader_result = eval_result["Reader"]
reader_result.head()



metrics = eval_result.calculate_metrics()
print(f'Retriever - Recall (single relevant document): {metrics["Retriever"]["recall_single_hit"]}')
print(f'Retriever - Recall (multiple relevant documents): {metrics["Retriever"]["recall_multi_hit"]}')
print(f'Retriever - Mean Reciprocal Rank: {metrics["Retriever"]["mrr"]}')
print(f'Retriever - Precision: {metrics["Retriever"]["precision"]}')
print(f'Retriever - Mean Average Precision: {metrics["Retriever"]["map"]}')

print(f'Reader - F1-Score: {metrics["Reader"]["f1"]}')
print(f'Reader - Exact Match: {metrics["Reader"]["exact_match"]}')