### A deep dive into why RAG doesn't always work as expected: an overview of the business value, the data, and the technology behind it.

![Photo by [Lisa Boonaerts](https://unsplash.com/@lisaboonaerts?utm_source=medium&utm_medium=referral) on [Unsplash](https://unsplash.com?utm_source=medium&utm_medium=referral)](https://miro.medium.com/0*fYvhotONLl8v5xbg)

Building a RAG (short for **R**etrieval **A**ugmented **G**eneration) to "chat with your data" is easy: install a popular LLM orchestrator like [LangChain](https://python.langchain.com/v0.2/docs/tutorials/rag/) or [LlamaIndex](https://docs.llamaindex.ai/en/stable/examples/low_level/oss_ingestion_retrieval/), turn your data into vectors, index those in a vector database, and quickly set up a pipeline with a default prompt.

A few lines of code and you call it a day.

Or so you'd think.

The reality is more complex than that. Vanilla RAG implementations, purposely made for 5-minute demos, don't work well for real business scenarios.

Don't get me wrong, those quick-and-dirty demos are great for understanding the basics. But in practice, getting a RAG system production-ready is about more than just stringing together some code. It's about navigating the realities of messy data, unforeseen user queries, and the ever-present pressure to deliver tangible business value.

> _In this post, we'll first explore the **business imperatives that make or break a RAG-based project**. Then, we'll dive into the common technical hurdles - from **data handling** to **performance optimization** - and discuss **strategies** to overcome them._

**Disclaimer**: The insights shared here don't represent my employer and come from my personal experiences, research, and more than a few late-night coding sessions.

---

## 1 - Clarify the business value from the start: the context, the users, and the data

_"Why should we bother building a RAG in the first place?"_

![Photo by [Mayukh Karmakar](https://unsplash.com/@wrishi2004m?utm_source=medium&utm_medium=referral) on [Unsplash](https://unsplash.com?utm_source=medium&utm_medium=referral)](https://miro.medium.com/0*1gxWJJe6HodZe6gX)

Before writing a single line of code, it's critical to understand why a RAG (Retrieval-Augmented Generation) is even needed from a business perspective. This might seem obvious, but many developers neglect this part, rushing into implementation headfirst without clearly defining long-term objectives.

Let's keep you from losing time in the future. Here are some business requirements to consider before starting a RAG/LLM-based project. These principles also apply to general ML projects:

→ **Clarify the context:** Know your users and what they do. Formulate their main business issue in simple terms, put yourself in their shoes, dissect what they do, and then discuss how RAGs and LLMs can help. Take sample questions and simulate how the system would handle them.

→ **Educate non-technical users** on the capabilities and limitations of generative AI. Since this is a new field, this is very helpful. This can be achieved through workshops, training sessions, and practical demonstrations that use RAG systems. For example, I've seen that internally crafted prompting guides are often helpful for getting started with interacting with LLMs.

→ **Understand the user journey:** What types of questions will they answer with the RAG? What are the outputs to expect from such a system? How will the generated answers be used down the line? 
Most importantly, you must know how your RAG will integrate into an existing workflow. This foresight will anticipate further developments, such as whether the RAG will be embedded into a browser extension, an API endpoint, or a Word plugin.
Generating an answer using a RAG system is simple. What's complex, however, is driving practical value from it.

> _**Keep this in mind: the business won't come to you and play with your fancy models unless those change and improve their ways of working.**_

→ **Anticipate the data to be indexed:** Qualify it, map it to the users, and understand why and how it will be used to form a good answer when the RAG pipeline is triggered. This will determine what processing and metadata should be implemented. After qualification, you'll eventually need to set up a data acquisition strategy: purchasing, leveraging internal data, discarding unnecessary data, or sourcing from open resources (open data, GitHub repos, etc.).

If a process heavily relies on business requirements, it must be identified early on at this step.

→ **Define success criteria:** What is a correct answer? What are the key success factors? How can we establish a clear way to compute the ROI? These metrics should not be evaluated only when the project is done. They should be iterated continuously throughout the project to catch early mistakes, easy bugs, and inconsistencies.

---

> Personal note: If the business asks you to build a RAG, one possible reason could be they've seen the competition doing it (FOMO is a real thing, my friend). My advice to you in this situation is to challenge this request first. Very often, what the business needs can be less complex than we think.

## 2 - Understand what you're indexing

After mapping and qualifying the data sources needed to build a RAG, you'll quickly identify different kinds of modalities that will be indexed upon further discussion with the business.

- text

- images and diagrams

- tables

- code snippets

Each of these modalities will be processed differently, turned into vectors, and used in retrieval.

There are different approaches to combining multimodal data: here's a common one that deals with **text**, **tables,** and **images**:

- text data is chunked and embedded with an embedding model

- tables are summarized with an LLM and their descriptions are embedded and used for indexing. After it's retrieved, a table is used as-is, in its raw tabular format.

- code snippets are chunked in a special way (to avoid inconsistencies) and embedded using a text embedding model

- images are converted into embeddings using a multi-modal vision and language model - When retrieval is performed, the same multimodal LLM will take in your text query convert it to a vector and search related images in the vector db.

![Diagram by the author](https://miro.medium.com/1*SzmZldHka0NIzIK8OO7vnQ.png)

Additional notes:

- The vectors you index are not necessarily the vectors you retrieve: you can do things differently: For example, you can index sentences by the paragraphs they occur into, by the questions they answer, or by their summary. Check this [post](https://medium.com/towards-data-science/3-advanced-document-retrieval-techniques-to-improve-rag-systems-0703a2375e1c) to learn more.

- There are a lot of great resources on multimodal RAGs. Check this [blog](https://docs.llamaindex.ai/en/v0.10.17/examples/multi_modal/multi_modal_pdf_tables.html) from LlamaIndex for a deep dive.

## 3 - Improve chunk quality - garbage in, garbage out

Before indexing text data, you need to break it into smaller pieces called chunks. Chunks are the text snippets the vector database retrieves and passes to the LLM as a context to generate an answer.

So it's obvious that the chunks' quality impacts the answer.

If the chunks:

- are pulled out of their surrounding context (if cut in the middle for example)

- include irrelevant data that doesn't answer the question

- contradict each other

they'll provide a poor answer.

T[[here](https://antematter.io/blogs/optimizing-rag-advanced-chunking-techniques-study)](https://www.mongodb.com/developer/products/atlas/choosing-chunking-strategy-rag/) are different chunking techniques that you can explore here and here.

Other [techniques](https://python.langchain.com/v0.1/docs/modules/data_connection/document_transformers/) depend on the data type (raw text, markdown, code).

However, what works best in general is to analyze the data precisely and come up with a chunking rule that makes sense from a business perspective:

Here are some tips:

- Leverage document metadata like table of contents, titles, or headers to provide contextually relevant chunks. For example, a chunk that overlaps between an introduction and the first chapters is not consistent and rarely makes sense

- There's no rule of thumb regarding chunk size. If your documents are wordy and express a single idea in relatively long paragraphs, the chunk size would be longer than documents that are written in bullet points

- Some data don't need chunking because it's relatively short and self-contained. Imagine building a RAG-based system on JIRA tickets: you won't need chunking for that.

> _Note on semantic [chunking](https://python.langchain.com/v0.2/docs/how_to/semantic-chunker/): this method generates chunks that are semantically relevant. It's however time consuming since it relies on embedding models underneath._

Resources about chunking:

- [https://towardsdatascience.com/the-art-of-chunking-boosting-ai-performance-in-rag-architectures-acdbdb8bdc2b](https://towardsdatascience.com/the-art-of-chunking-boosting-ai-performance-in-rag-architectures-acdbdb8bdc2b)

## 4 - Improve pre-retrieval

Before your query reaches the RAG system, you can refine it with additional processing steps.

These steps are called pre-retrieval: they optimize the input query, ensuring the system retrieves the most relevant and high-quality documents.

Here are some key pre-retrieval steps to consider ⤵️

### **✍️ Query rewriting**

When users ask questions, they often don't express themselves as clearly as they should. Their intention might be ambiguous, the formulation not clear enough, and important details might be missing. The question could also be too short for the system to provide relevant answers. I've seen examples of questions that were single words.

To fix this, you can use an LLM to rephrase this query before sending it to the vector database.

You can also make an LLM interact with the user in a chat and ask for clarification (think of agents here).

Check this [paper](https://arxiv.org/abs/2305.03653) about query expansion to learn more.

### 💥  **Query Expansion with Hypothetical Document Embedding (HyDE)**

HyDE is a [method](https://arxiv.org/abs/2212.10496) that boosts retrieval. It's meant to generate a hypothetical answer that may look similar to a true answer but with potential inaccuracies. This fake answer is then embedded and used to retrieve real vectors (i.e. chunks) from the database.

Experiments demonstrate that HyDE consistently outperforms the state-of-the-art unsupervised dense retriever Contriever and exhibits robust performance comparable to fine-tuned retrievers across various tasks (such as web search, QA, and fact verification) and languages.

Similarly, Gao et al. ([2023a](https://arxiv.org/html/2405.06211v3#bib.bib41)) propose the Hypothetical Document Embedding (HyDE) method, which instructs an LLM to generate hypothetical documents for the given query. The hypothetical documents are then used as new queries to get embedded and search for neighbors with the dense retriever.

![Source: HyDE [paper](https://arxiv.org/abs/2212.10496)](https://miro.medium.com/1*Y8xTtXHqQT7cKkXMfKfhxQ.png)

### **Query augmentation**

Yu et al. ([2023c](https://arxiv.org/html/2405.06211v3#bib.bib184)) propose **query augmentation** to combine the original query and the preliminary generated outputs as a new query, which is further used to retrieve relevant information from the external database. The retrieved results can inspire the language model to rethink and enhance the generated results.

Compared to applying only the original query, such augmentation may contribute more relevant information retrieved from the corpus for the direct clarification of query-output relationships. Including initial output in the new query further enhances the lexical and semantic overlap between the supporting documents to be retrieved with the given question. Query augmentation achieves overall better performance among these query enhancement strategies since it may process all retrieved knowledge collectively while generating answers (Wang et al., [2024c](https://arxiv.org/html/2405.06211v3#bib.bib156)).

## 5 - Improve retrieval

The retrieval step takes in the query (whether in a raw format or altered by pre-retrieval steps) to fetch the most relevant documents from the vector database.

While this can be efficiently performed using vector similarity, it can still be enhanced with additional techniques.

### Hybrid Search

Hybrid search is a method that combines vector search and keyword search. It allows you to combine the advantages of the two techniques, thus maintaining control over the semantics while matching the exact terms of the query.

This technique matters when you search for specific keywords that the embedding model isn't trained on / or is incapable of matching with vector similarity (e.g. product names, technical terms, alphanumerical codes, etc.).

Multiple databases implement this feature by combining the dense search (powered by similarity measures on top of vectors) and keyword search (powered by the BM25 algorithm).

Here's how [Pinecone](https://www.pinecone.io/learn/hybrid-search-intro/) implements it.

![Diagram by the author](https://miro.medium.com/1*WrrEp7fpYHF-l2486yHEpQ.png)

### Filter on metadata

Each vector you index can have additional properties that we call metadata. When querying the database, you can use this metadata to pre-filter the space of vectors.

While this is very cheap to compute, it can tremendously increase the quality of the results from a business perspective.

Let's say you indexed customer reviews with the location as part of the metadata. Now let's say you want to use this data to learn more about a particular product (e.g. The iPhone) but in the US.

Instead of asking "How is the iPhone product perceived in the USA?", you can pre-filter the results on the US location and search for this query "How is the iPhone perceived?"

This is more efficient: it guarantees better search results targeted towards a clearly defined segment.

### Test multiple embedding models

The embedding model is a crucial component in the retrieval step: it's the model that converts your text data into fixed-size numerical vectors.

There are multiple embedding models to use that are either proprietary or open source.

If you're unsure which one to use, refer to the Massive Text Embedding benchmark (MTEB) [leaderboard](https://huggingface.co/spaces/mteb/leaderboard).

![Source: MTEB [leaderboard](https://huggingface.co/spaces/mteb/leaderboard)](https://miro.medium.com/1*o_wC6vmjH9huovXo-eiVKg.png)

### Fine-tune an embedding model

Embedding models are often trained on general knowledge, which limits their effectiveness for company or domain-specific adoption. Customizing embedding for your domain-specific data (e.g. legal or finance) can significantly boost the retrieval performance of your RAG Application.

If you have positive pairs of related sentences like (query, context) or (query, answer), you can use them to finetune an embedding model.

Here's a blog [post](https://www.philschmid.de/fine-tune-embedding-model-for-rag) that shows how to fine-tune an embedding model for a financial RAG application.

## 6 - Improve Post-retrieval:

The goal of the post-retrieval techniques is to increase the relevancy of the documents after they are extracted from the database.

Here are two of them.

### Reranking

One popular technique is reranking which aims at re-ordering the documents based on their alignment/relatedness with the query.

There are multiple reranking [model](https://huggingface.co/cross-encoder/ms-marco-MiniLM-L-2-v2)s to choose from both open source and proprietary: I use this model from HuggingFace, but you can rely on proprietary models like [Cohere](https://cohere.com/rerank) re-ranker as well

### Remove irrelevant chunks

You can also instruct an LLM to post-process the retrieved documents. This can help rerank the documents and filter out unimportant sections or chunks. As this technique relies on an LLM only, use it with caution as it might incur high costs or induce hallucinations.

## 7 - An overlooked part: Generation

Once the documents are retrieved and processed to be as relevant as possible to the query, they are passed to the LLM as a context to generate the answer.

Although this step is of utmost importance, many people don't pay enough attention to it in the RAG workflow and only focus on the retrieval part.

Here are some practical tips that could enhance answer generation:

- Define a system prompt to guide your RAG, make it "behave" in a specific way, and write in a particular style. This is easy to implement and has tangible business impacts. Eg. "You're an experienced financial analyst. Your role is to explain to me financial reports like I'm 5. Be as precise as possible."

- Include a few shot examples in your system prompt. If the task you're instructing the LLM to perform is complex, add some input/output example pairs. The more realistic the examples, the better the answer will be.

- Force your LLM to generate structured outputs whenever they make sense to your business logic. Having structured outputs allows you to integrate your LLM in a pipeline.

- Some generation tasks require reasoning, summing up results or even taking a step back (as this was proven efficient) when generating text. That's where [Chain Of Thought](https://arxiv.org/abs/2201.11903) comes into play.

Multiple frameworks perform these tasks. The one I particularly prefer is [DSPY](https://github.com/stanfordnlp/dspy). It covers all these functionalities and provides an interesting paradigm to optimize prompt engineering.

## Conclusion

This isn't just a conclusion but more of a starting point.

If your project is heading into production and being adopted by the business (congratulations!), building the RAG is just the beginning. RAGs, like traditional ML models, require ongoing attention after they're built and tested locally.

Once deployed, they need to be:

- Served, whether through a REST API, web application, or integrated into platforms like WhatsApp or Teams.

- Monitored, with careful tracking of key metrics such as cost and performance.

- Updated regularly, ensuring a robust data ingestion lifecycle is in place.

## References

- Retrieval-Augmented Generation for Large Language Models: A Survey [[link](https://arxiv.org/abs/2312.10997)]

- 17 (Advanced) RAG Techniques to Turn Your LLM App Prototype into a Production-Ready Solution [[link](https://towardsdatascience.com/17-advanced-rag-techniques-to-turn-your-rag-app-prototype-into-a-production-ready-solution-5a048e36cdc8#92c6)]