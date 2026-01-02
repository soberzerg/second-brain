Knowledge graphs have become increasingly important for structuring information and enabling advanced querying and reasoning capabilities. But what's the best way to construct them? In this post, we'll compare **traditional named entity recognition (NER)** approaches with newer **large language model (LLM) methods** for knowledge graph construction.

Before we dive in, again, as our valued readers, if you have anything on your mind that we may be able to help, fill out this form below!👇

[Channel feedback form](https://noteforms.com/forms/twosetai-youtube-content-sqezrz)

## The Basics of Knowledge Graphs

A knowledge graph is a network of entities and their interconnections or relationships. They allow us to create structured, machine-readable information from unstructured text that can be used for reasoning and querying. Knowledge graphs power many applications including search engines, recommendation systems, and question answering.

Constructing a knowledge graph typically involves several steps:

1. _Processing and cleaning text data_

2. _Extracting entities from the text_

3. _Identifying relationships between entities_

4. _Building the graph structure_

5. _Curating and refining the graph_

![[Source](https://towardsdatascience.com/integrate-llm-workflows-with-knowledge-graph-using-neo4j-and-apoc-27ef7e9900a2)](https://miro.medium.com/0*M-ue6gIkrz5PlsNe.png)

## Traditional NER Approaches

Traditional NER techniques have been around for decades and are a mature research area. They include:

- _Rule-based approaches_

- _Machine learning models like conditional random fields_

- _Deep learning models like BiLSTMs_

- _Pre-trained models like spaCy and BERT_

Advantages:

- _Very precise, especially for well-defined domains_

- _Transparent and interpretable_

- _Computationally efficient_

Disadvantages:

- _Less scalable across diverse datasets_

- _Harder to adapt to new contexts_

- _Require ongoing maintenance and retraining_

## LLM-Based Approaches

With the rise of large language models, many are now using prompting techniques to extract entities and relationships.

Advantages:

- _General and adaptable across domains_

- _Strong contextual understanding_

- _Quick to set up with minimal fine-tuning_

Disadvantages:

- _Resource intensive and computationally expensive_

- _Less transparent ("black box")_

- _Dependent on training data quality/coverage_

## Choosing the Right Approach

Traditional NER approaches tend to work best for:

- _Domain-specific applications (medical, legal, financial)_

- _Use cases requiring very high precision_

- _Situations where errors are costly_

LLMs can be good for:

- ...

A Hybrid Approach

For many real-world applications, a hybrid approach combining traditional NER with LLMs may be ideal. In our sample implementation:

...

## Curious to delve deeper into this?

**Join Professor Mehdi and myself for a deep-dive discussion about:**

- **which approach to choose**

- **how to use hybrid approach, and**

- **a step-by-step code walk through of a simple KG construction, in the video below!👇** 

<iframe src="https://cdn.embedly.com/widgets/media.html?src=https%3A%2F%2Fwww.youtube.com%2Fembed%2FOsnM8YTFwk4%3Ffeature%3Doembed&display_name=YouTube&url=https%3A%2F%2Fwww.youtube.com%2Fwatch%3Fv%3DOsnM8YTFwk4&image=https%3A%2F%2Fi.ytimg.com%2Fvi%2FOsnM8YTFwk4%2Fhqdefault.jpg&key=a19fcc184b9711e1b4764040d3dc5c07&type=text%2Fhtml&schema=youtube" title="" height="480" width="854"></iframe>

Knowledge graphs are a powerful way to structure information, but choosing the right construction approach is key. By understanding the tradeoffs between traditional NER and LLM-based methods, you can build more effective, efficient, and reliable knowledge graph systems.

**Stay tuned as we continue exploring the development of knowledge-augmented AI systems to extract maximum value from unstructured data sources!**

> 🛠 ️✨ Happy practicing and happy building! 🚀🌟 

---

Thanks[ ](https://twitter.com/Angelina_Magr)for reading our newsletter. You can follow us here: Angelina[ [Linkedin](https://www.linkedin.com/in/mehdiallahyari/) ](https://www.linkedin.com/in/meetangelina/)or [[Twitter](https://twitter.com/MehdiAllahyari)](https://twitter.com/angelina_magr) and Mehdi Linkedin or Twitter.

Source of images/quotes:

📽 ️ Our other KG + RAG videos:

<iframe src="https://cdn.embedly.com/widgets/media.html?src=https%3A%2F%2Fwww.youtube.com%2Fembed%2Fa6VWF_DpWDU%3Ffeature%3Doembed&display_name=YouTube&url=https%3A%2F%2Fwww.youtube.com%2Fwatch%3Fv%3Da6VWF_DpWDU&image=https%3A%2F%2Fi.ytimg.com%2Fvi%2Fa6VWF_DpWDU%2Fhqdefault.jpg&key=a19fcc184b9711e1b4764040d3dc5c07&type=text%2Fhtml&schema=youtube" title="" height="480" width="854"></iframe>

<iframe src="https://cdn.embedly.com/widgets/media.html?src=https%3A%2F%2Fwww.youtube.com%2Fembed%2FQSZHGGRouIE%3Ffeature%3Doembed&display_name=YouTube&url=https%3A%2F%2Fwww.youtube.com%2Fwatch%3Fv%3DQSZHGGRouIE&image=https%3A%2F%2Fi.ytimg.com%2Fvi%2FQSZHGGRouIE%2Fhqdefault.jpg&key=a19fcc184b9711e1b4764040d3dc5c07&type=text%2Fhtml&schema=youtube" title="" height="480" width="854"></iframe>

📚  Also if you'd like to learn more about RAG systems, check out our book on the RAG system:

[Order a copy!](https://angelinamagr.gumroad.com/l/practical-approach-to-RAG-systems)

📬  Don't miss out on the latest updates - Subscribe to our newsletter: [The MLnotes Newsletter](https://mlnotes.substack.com/?utm_source=substack&utm_campaign=publication_embed&utm_medium=web)