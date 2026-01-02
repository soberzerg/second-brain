
![Simple is Beautiful](https://miro.medium.com/0*1Lt02McIl0tjg0Ah)


**Introduction**In my last[ article](https://medium.com/madhukarkumar/building-blocks-of-agi-how-agent-architecture-is-shaping-the-way-we-build-agi-systems-3672b4dd8b56), I drew parallels between the evolution of life and the progression of human innovation, tracing a cyclic pattern where simplicity births complexity, which in turn seeks simplicity again. A single cell multiplies, differentiates, and eventually forms a complex organism capable of myriad functions.

In this rhythmic evolution of simplicity to complexity, what does stand out are things that do multiple things at once, bringing simplicity at scale. Consider feathers on a bird - They are crucial not just for flight, providing lift and control, but they also add insulation, keeping birds warm in cold temperatures. In some species, the coloration and pattern of feathers play a role in camouflage, mating displays, and social signaling, all of which are crucial to survival.

This pattern isn't confined solely to biology. It's also evident in our creations. Consider the iPhone, an epitome of multi-functionality, born out of the quest for simplicity. The day it was birthed, the iPhone combined multiple specialized devices' functions by integrating them into a simple, easy-to-use interface (one could say the same thing about CRMs and Operating Systems).

So why am I talking about this in the context of Gen AI and databases?

Let me explain.

In the realm of Generative AI applications, there's a widespread belief that you always need vector-only databases to contextualize your data to Large Language Models (LLMs). At the risk of being bombarded with angry comments, I am here to say you don't.

_**In fact, adding a vector-only database to an app or a service is an anti-pattern to simplicity because vector-only databases can only do one thing - storing and searching vector data.**_

Let's break this down. There are broadly two big categories in the world of building applications, including Gen AI applications - **a low-code/no-code way of building apps** and an **enterprise world** that requires complex integrations with non-trivial requirements.

When it comes to Gen AI, in both of these categories, to build a custom app, you need three fundamental building blocks - the apps should have access to **custom knowledge** (the data you provide to the LLMs), **custom instructions** (these give a unique characteristic to your LLM based apps) and finally access to **tools** (the ability to invoke other APIs and apps to execute specific actions).

### No-code/Low-code Gen AI Apps

As of writing this article, there are more tools than I can count that help build Gen AI apps or custom chatbots in a low-code/no-code way. **Until a week ago, using any of these tools required you first to download or sign up for a vector-only database. Now, you don't.** Let's look at a few examples of these:

1. **[Flowise](https://docs.flowiseai.com/)** - An open-source no-code tool based on LangChain that allows you to build "flows," a.k .a. a continuous set of steps to do a task. Once you have built a flow, you can run it manually or call its API endpoint through other no-code tools like Zapier or Make (formerly Integromat). In Flowise, you do have to choose a vector store if you are looking to build something based on your data. Still, I won't be surprised if they added support for the OpenAI Assistants APIs that do not require any vector-only databases to store data.

2. **[RelevanceAI](https://relevanceai.com/)** - A paid tool that is very similar to OpenAI custom GPT. You don't need a vector-only database to build your own custom AI. With Relevance, you can upload your data just like OpenAI GPT, and you don't need to sign up or purchase another vector-only database.

3. **[Voiceflow](https://www.voiceflow.com/knowledge-base)-** A paid tool that allows you to build your custom bot or LLM-based app and connect it to other applications. You don't need a Vector-only database to build this.

4. **[Botpress](https://botpress.com/docs/)** - Very similar to the other tools mentioned above. You don't need a vector-only database to provide knowledge to your application built on Botpress.

It is important to note that the tools mentioned above are only a sliver of options available to build AI apps in a low-code/no-code way. There are existing low-code tools like[ Bubble](https://bubble.io/),[ Zapier](https://zapier.com),[ Make](https://www.make.com/en),[ n8n](https://n8n.io/), and[ Tooljet](https://www.tooljet.com/) that now also have Gen AI capabilities and can be used to create Gen AI-based apps.

**Enterprise Gen AI Apps**

When we talk about building Gen AI apps for Enterprises, we are not talking about just another use case but a whole other world rife with complexity and volume. We are talking about software architecture and tech stacks that may have hundreds and thousands of existing API endpoints, data pipelines, and different teams, all built in different programming languages with tons of CI/CD pipelines and, above all, a bottomless pit of data that, have the following traits - 1) There are multiple data types from SQL, NoSQL to CSVs to Parquet to HDFS based files to binary data to Timeseries to name a few, 2) The volume of data is typically in terabytes and petabytes, and finally) There may be transactional and analytics databases, data lakes, and data warehouses to deal with all of these data.

If I were to show how this data complexity looks like in a simple image, this is what it would look like.

![Visualizing the Complexity of an Enterprise Data Architecture](https://miro.medium.com/0*BF7jj8QYmXqAnKi4)

I am kidding, of course. It would actually look a little like this.

![Simplified Data Architecture of an Enterprise](https://miro.medium.com/0*EX13yilF3_ytU4HC)

Now, imagine you are building an LLM-based app that is obviously oblivious to all of this data because it was trained on a different dataset, and it has no knowledge about your company's corpora of data.

Y**ou have three choices to now make your LLM aware of this data -**

**1) Re-train your LLM**

**2) Fine Tune LLMs**

**3) Build your app using Retrieval Augmented Generation (RAG).**

I am assuming you don't have millions of dollars, tons of GPUs, and a clean dataset to train/retrain your LLMs, so you can either fine-tune an LLM and/or use RAG. Most companies end up implementing a combination of fine-tuning and RAG. It is important to note, though, that fine-tuning is only for a specific model and for a specific behavior. Hence, if either of those two changes, which happens a lot these days, you have to fine-tune a new model and continue feeding with the new data.

Now, let's look at a typical RAG-based architecture when building an enterprise-grade Gen AI app. The diagram below is a simplified version of a reference architecture.

![Reference Architecture of an Enterprise Grade LLM App](https://miro.medium.com/0*XNx2xO7nhRe-E-IL)

In this architecture, if you are looking to use RAG to search and curate data from the bottommost layer, we now have a choice of either complicating this architecture by adding yet another database that only does one thing, aka a vector-only database or figuring out how to simplify this architecture yet fulfill all the enterprise requirements.

Based on what we have discussed so far, I would categorize the enterprise into three big buckets captured in the image below - Multiple data types, transaction and analytics, and hybrid search across massive amounts of data.

![The Three Major Requirements of an Enterprise Data Architecture](https://miro.medium.com/0*Gxx4RSuW9Gd8_NSp)

But first, let's examine why there has been such hype for vectors and vector-only databases recently. RAG, simply put, is a way to search massive amounts of data and then retrieve the result, which is mostly similar to the search query. In this case, the classic way of exact keyword match, aka lexical search, doesn't work because if the user asks a question like - "Who was the CEO of our company in 2020?" there may be no match if a document consists of a sentence that says - "In 2020, the company was led by John Doe."

This is where semantic search comes in. Semantic search is a methodology to search for data closer to each other in meaning vs an exact character or word match. It is achieved by first converting the data that needs to be searched to a set of vectors or numbers separated by commas.

To put this in plain English, imagine if you took all objects in a room and gave it a location number like latitude and longitude (except that vectors have 1000s of dimensions), and each object would have a set of numbers for its location. In this space objects that are similar are closer to each other; for example, words like King, Boy, Prince vs Girl, Queen, or Princess would have numbers/vectors that would be closer to each other. Here is another simplistic representation of turning data into embeddings or vectors.

![Visualizing Vectorization of Data](https://miro.medium.com/0*EJpDqF243po2nQ7D)

When it comes to converting data to vectors and doing a semantic search, there are broadly three steps: 1) Create vectors or embeddings (you use this by using a model), 2) You store and index the vectors, and 3) You run a semantic search against the data.

For 3) typically, you can use a cosine similarity algorithm or measure the exact distance between the objects using something like an Euclidean distance algorithm. However, most semantic search works great for unstructured data like pdf and docs. You don't need vectors if the data is structured in an SQL table because you can mix and match the data by joining tables.

So what happens now if your data is of different data types - SQL, JSON, Binary, etc. and it is incredibly vast and has new data flowing in at an incredibly fast pace?

Here is a diagram of what it would look like to add yet another database into the mix.

![Adding Complexity to an Existing Complex Data Architecture](https://miro.medium.com/0*uwKyq0A8n4BWSjWf)

Other than the fact that now more data movement and cost are added to the overall architecture, there is an even bigger problem with this architecture choice . Since Vector-only databases can only store vectors and a very small amount of metadata (for example, Pinecone has a limit of only 40 kb of metadata), you now have to make two calls: 1) to search the vector and 2) to retrieve the actual data by looking up the meta data which may be sitting in a whole different database.

## Challenges with Vector-only Databases in Enterprise

To summarize, there are three significant issues with vector-only databases

1. It can only manage vectors, so you still have to fetch, mix, and match your SQL, JSON, Binary, and all other data elsewhere.

2. The overall process could become expensive depending on how often you create vectors.

3. The architecture is NOT real-time because you may have a bunch of new data that is not immediately converted to vectors since some databases like Pinecone have a time lag between upserting a vector and when it becomes available for search.

![Screenshot of Pinecone Documentation](https://miro.medium.com/0*LHIhscCT2O4jH-mI)

Finally, given that many vector-only databases have been created in the last couple of years, some still do not have basic database properties like ACID compliance, redundancies, and disaster recovery.

Depending on how you see it, fortunately or unfortunately, when it comes to choosing databases, there are over 300 choices!

## Exploring Database Alternatives and Capabilities

Let's take a tour through the database landscape to understand our options better:

- **Vector-only Databases:** Tools like Pinecone, Weaviate, Qdrant (incidentally, Grok LLM uses Qdrant, so if it is a good enough DB for a LLM, it may be a good choice if you have a similar use case), and Milvius specialize in vector storage and searches only. However, they often fall short of meeting the comprehensive needs of an enterprise, such as handling diverse data types and supporting real-time analytics. As we noted earlier, they only do one thing, so they add to the complexity, cost, and latency.

- **Postgres with PG Vector:** This option excels in transactional processing and semantic search but lacks analytics capabilities. If your use case requires mixing and matching both SQL and JSON data, then you should consider other choices.

- **MongoDB with Vectors:** MongoDB adapts well to transactional, and recently it added support for vectors. If your use case is to only do semantic searches across JSON, then this is a good option. Still, if you are looking for support for multiple data types, the ability to run analytics, and support for SQL, then you should look for other options.

- **Elasticsearch:** Known for its prowess in lexical and semantic searches, Elasticsearch, however, does not cater to analytics and transactional use cases. Its approach to semantic search, especially with the recent vector search feature, remains opaque. It is still a good choice for doing searches but not necessarily the choice for using it as a sole database for transactional and analytics use cases.

- **SingleStore:** Standing out in this crowd is SingleStore. It ticks most boxes by handling transactional and analytics workloads in real-time, managing fast data ingestion, and offering vector support, albeit with certain limitations in KNN (k-nearest neighbors) queries. It has support for SQL and JSON, can do transactions and analytics, and has support for both lexical and semantic search.

There are, of course, a lot more choices. For example, even Neo4J, a Graph base DB, now has support for vectors, as does Redis, a key/value in-memory database. These choices include databases that can do more than one thing, which is the key for any enterprise-grade application.

## Conclusion: The Art of Simplicity in Database

In conclusion, simplicity is one of the most sophisticated and the hardest things to do. As builders, we make choices every day (the hardest one being naming variables). In my opinion, it is essential to make choices that make things simpler by picking things that do multiple things very well, and not by adding to the complexity by picking things that only do one thing. This is essential to how we evolve existing technologies to amplify our capabilities collectively in a scalable fashion.

Simplicity scales.