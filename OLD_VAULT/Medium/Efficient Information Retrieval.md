
![](https://miro.medium.com/0*E2Flv8LJglvGq4pi.jpeg)

## Introduction

Retrieval Augmented Generation (RAG) breaks free from knowledge limitations, incorporates external data, and enhances contextual understanding.

Its popularity is soaring due to its efficiency in integrating external data without continuous fine-tuning.

![](https://miro.medium.com/0*nL3udE9i0lzrP0b0.png)

_Let's explore how RAG overcomes LLM challenges!_

## LLM Knowledge Limitations

Large language models confront several challenges related to the accuracy and currency of their knowledge. Two common issues are hallucination and knowledge cut-off.

- **Hallucination**: It occurs when a model confidently produces an incorrect response. For instance, if a model claims 'googly retriever' is a real dog breed, it's a hallucination, potentially leading to misleading information.

![Hallucinations](https://miro.medium.com/1*ZPsbIr_oaN0PPCSxYmf5Zw.png)

- **Knowledge cut-off**: It is when an LLM returns information that is outdated according to the model's training data. Every foundation model has a knowledge cut-off, meaning its knowledge is limited to the data available at the time of training. For instance, if you ask the model about the most recent NBA championship winner, it may respond with outdated information.

![Knowledge cut-off](https://miro.medium.com/1*2uXAx6WtTu15BV813yaSig.png)

RAG offers a technique to _mitigate_ these challenges. It enables you to provide the model with access to external data sources, mitigating hallucinations by introducing factual context and overcoming knowledge cut-offs by incorporating current information.

## Retrieval-Augmented Generation (RAG)

Retrieval-Augmented Generation (RAG) is a versatile framework that grants Large Language Models (LLMs) access to external data beyond their training data. RAG is not tied to a single implementation; it accommodates various approaches for different tasks and data formats.

It enables LLMs to tap into external data sources, including knowledge bases, documents, databases, and the internet, during runtime. This is invaluable for enhancing language models with external data, bridging knowledge gaps not covered in their training data.

![Efficient indexing of documents for quick retrieval](https://miro.medium.com/1*_-EGjc4ALzNf0AhB6o5JgA.png)

To efficiently retrieve information from documents, a common practice is to index them in a vector database, using embedding vectors that capture semantic meaning. Additionally, _chunking_ is applied to large documents to improve relevance and reduce noise, ultimately enhancing the model's responses by providing specific contextual information.

## The Framework

There are two key models within RAG framework:

- **RAG-Sequence Model:** This model utilizes the same retrieved document to generate the complete sequence. It treats the retrieved document as a single latent variable that is marginalized to get the sequence-to-sequence probability via a _top-K approximation_. In this approach, the top K documents are retrieved using the retriever, and the generator computes the output sequence probability for each document. These probabilities are then combined through marginalization.

- **RAG-Token Model:** In this model, a different latent document can be drawn for each target token, allowing the generator to choose content from several documents when producing an answer. Similar to the RAG-Sequence model, it retrieves the top K documents and then generates a distribution for the next output token for each document. This process is repeated for each output token, with _marginalization_ occurring accordingly.

![](https://miro.medium.com/0*nozM2e7zprOsLE64.png)

Additionally, RAG can be employed for _sequence classification tasks_, treating the target class as a single-sequence target. In this case, RAG-Sequence and RAG-Token models become equivalent.

## Components of RAG

- **Retriever**: The Retriever (_**DPR**_), which retrieves relevant documents based on a query and a document index. The retrieval component is based on _Dense Passage Retrieval_ (DPR) and employs a bi-encoder architecture with dense and query representations derived from BERT. The top-K documents with the highest prior probability are selected, making use of a _Maximum Inner Product Search_ (MIPS) algorithm.

- **Generator**: The Generator component, based on BART-large, is responsible for generating sequences. It combines input with retrieved content simply by concatenating them.

![](https://miro.medium.com/1*3NgTaJX_lTYUz_8QZ6_kVQ.png)

### Training Phase

During training, both the retriever and generator are trained jointly without direct supervision on which document to retrieve. The training objective minimizes the _negative marginal log-likelihood_ of each target.

### Decoding Phase

In the decoding phase, RAG-Sequence and RAG-Token models require different approaches. RAG-Token uses standard _autoregressive sequence generation_ with a beam decoder. In contrast, RAG-Sequence runs beam search for each document and scores hypotheses using the generator probabilities. For longer output sequences, an efficient decoding approach is employed to avoid excessive forward passes.

## Implementation & Orchestration of RAG

Implementing RAG workflows can be complex, involving multiple steps from accepting the user prompt to querying the database, chunking documents, and orchestrating the entire process.

![](https://miro.medium.com/0*gNSvAkdZtqUoo6T3.jpg)

Frameworks like _LangChain_ simplify this process by providing modular components to work with LLMs and augmentation techniques like RAG. LangChain includes document loaders for various input formats, document transformers for splitting documents, and other components to streamline the development of LLM-powered applications.

## RAG Workflow with LangChain

LangChain, a comprehensive platform for natural language processing, plays a pivotal role in making RAG models accessible and efficient. Here's how LangChain fits into the RAG workflow:

![](https://miro.medium.com/0*7bAHwns0Y0YuwmhS.png)

### Document Loaders and Transformers

LangChain offers a wide array of document loaders that can fetch documents from various sources, including private S3 buckets and public websites. These documents can be of various types, such as HTML, PDF, or code. The Document Transformers component is responsible for preparing these documents for retrieval, including splitting large documents into smaller, more manageable chunks.

![](https://miro.medium.com/0*wCr6SLfsVz7nDND2.jpg)

### Text Embedding Models

Text embedding models in LangChain are designed to interface with various text embedding providers and methods, including OpenAI, Cohere, and Hugging Face. These models create vector representations of text, capturing its semantic meaning. This vectorization enables efficient retrieval of similar pieces of text.

### Vector Stores

With the rise of embeddings, efficient databases are needed for storing and searching these embeddings. LangChain offers integrations with over 50 different vector stores, making it easy to choose the one that suits your needs best.

![](https://miro.medium.com/0*3yVjD3sgf4B7-zCz.jpg)

### Retrievers

Retrievers in LangChain provide the interface to retrieve documents relevant to a query. These retrievers can use vector stores as their backbone but also support other types of retrievers. LangChain's retrievers offer flexibility in customizing retrieval algorithms, ranging from simple semantic search to advanced methods that enhance performance.

### Caching Embeddings

LangChain's Caching Embeddings feature allows embeddings to be stored or temporarily cached, reducing the need for recomputation and improving overall performance.

### Integration with Hugging Face

Hugging Face, a leading platform for transformer-based models, provides pre-trained models, including the ones used in RAG. LangChain seamlessly integrates with Hugging Face's models, enabling you to fine-tune and adapt them for your specific tasks.

![](https://miro.medium.com/0*Mcsg7uggRueeBnkq.jpeg)

## Conclusion

Retrieval-Augmented Generation (RAG) models represent a groundbreaking advancement in the field of large language model.

![](https://miro.medium.com/1*y5OgyU0Qy4IQHLIrtyq02A.png)

> **LangChain and similar frameworks make it easier to implement RAG and other augmentation techniques, enabling the rapid development of applications that leverage the full potential of LLMs.**

> **The synergy between these technologies opens up exciting possibilities for innovation in the realm of knowledge-intensive language tasks.**

---

This is the theory part, you were introduced to RAG workflow. Next part of this article will be the code implementation part. _Meet you soon!_

The next article in which t[here](https://medium.com/international-school-of-ai-data-science/implementing-rag-with-langchain-and-hugging-face-28e3ea66c5f7) is a code implementation of RAG, you can see here