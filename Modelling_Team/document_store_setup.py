import logging

logging.basicConfig(format="%(levelname)s - %(name)s -  %(message)s", level=logging.WARNING)
logging.getLogger("haystack").setLevel(logging.INFO)



import os
from haystack.document_stores import ElasticsearchDocumentStore

# Get the host where Elasticsearch is running, default to localhost
host = os.environ.get("ELASTICSEARCH_HOST", "localhost")
document_store = ElasticsearchDocumentStore(host=host, username="", password="", index="document")
document_store.delete_documents(index="document")



from haystack.utils import convert_files_to_docs
from haystack.nodes import PreProcessor

devices = os.listdir("Datasets")

for device in devices:
    doc_dir = os.path.join("Datasets", device)

    all_docs = convert_files_to_docs(dir_path=doc_dir, clean_func = lambda x:x.replace("-\n", "").replace("\n"," "), split_paragraphs=True)

    for doc in all_docs:
        doc.meta['device'] = device

    preprocessor = PreProcessor(
        clean_empty_lines=True,
        clean_whitespace=True,
        clean_header_footer=False,
        split_by="word",
        split_length=200,
        split_overlap=30,
        split_respect_sentence_boundary=True,
    )
    docs = preprocessor.process(all_docs)

    print(f"n_files_input: {len(all_docs)}\nn_docs_output: {len(docs)}")
    
    print(docs[:3])

    # Now, let's write the docs to our DB.
    document_store.write_documents(docs)




