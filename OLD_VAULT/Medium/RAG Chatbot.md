
_Hong T., Jing W. Jing Z. and Luchao J._

![_This research is partially funded by the OpenAI Research Program. photo is from [unsplash.com](https://unsplash.com/photos/green-leaf-on-book-VtNSaArmb-o)_](https://miro.medium.com/1*pANKexPLV6lfFa8S6zqjMw.png)

---

Having a completely free, low-latency, hallucination-free chatbot is the holy grail for large language model applications. This open-source RAG Chatbot is one step closer to that goal.

## **What is a reranker and why do we use it?**

A reranker uses a language model to evaluate and sort document chunks, selecting the most relevant documents to answer user questions. It is free (we use an open-source cross-encoder as a reranker) and high-performing.

There are many flavors of rerankers. A cross-encoder is a BERT-based model that evaluates the relevance between a query and documents and selects the most relevant documents to send to an LLM for high-quality answers. It balances speed with accuracy, and reranking methods emphasize better search results. Here, we use a cross-encoder from Hugging Face.

## Limitation of Embedding

Embeddings are designed to capture semantic information but often struggle to distinguish nuanced differences between similar phrases, like "I love apples" versus "I used to love apples," due to a lack of contrastive information. Embeddings are constrained by dimensionality, typically fixed at around 1024 dimensions, which can limit their ability to fully represent complex or lengthy documents and queries. Additionally, they cannot be generalized effectively to unseen content, which is crucial for real-world search applications. This limitation is often exacerbated by the fixed dimensionality and the constraints of the training data.

## How does a reranker work?

Under the hood, the cross-encoding reranker is a pretrained BERT model used to evaluate query, document pair relevancy. The input for the cross-encoder is a pair of queries and documents. The output is the ranking scores, which are suitable for evaluating search results and recommending products. Here, we use the reranker to select highly relevant documents for the LLM to answer user questions.
By processing both the query and document together, the model captures the nuances and contextual relationships between them (self-attention in transformers), leading to more accurate assessments of relevance.
The potential downside is latency and cost. For this study, we mitigate the cost of the reranker by using an open-source reranker and caching text preprocessing results into memory to reduce latency. Based on our test on a couple of megabyte PDF files, the latency is less than a couple of seconds.

comparison of current reranker models is conducted by [Galileo.AI](https://www.rungalileo.io/blog/mastering-rag-how-to-select-a-reranking-model)

![comparison of current reranker by Galileo.AI](https://miro.medium.com/1*QZV9T9h7wYOqLh9bNeKIhA.png)

---

## Architecture Comparison:

Reranker-based RAG simplifies the regular RAG steps (text tokenization, embedding, vector database creation, and similarity search) into one cross-encoding reranker. The top N most relevant text chunks are selected by the reranker to feed into an LLM like ChatGPT for answer generation.

The main difference is highlighted in the following dashed blue square.

![The cross-encoder reranks text chunks directly and filters to send the top K chunks to GPT-4o for answers.](https://miro.medium.com/1*mBKI3k7Xn-eU0VJOmQjzqg.png)

## Instructions for using the chatbot

A Streamlit interface is built to demonstrate the reranker-based RAG.
Users can copy/paste their own OpenAI API key and upload a PDF file on the left side. After a few seconds of text preprocessing, users can ask questions about their PDF.
As mentioned, the preprocessed document is cached into memory to reduce latency. Benefiting from the recent release of the ChatGPT-4o API, chatbot answers are satisfying.

![Input the API key and upload a PDF file using the leftside. After a few seconds, users can ask questions on the right side.](https://miro.medium.com/1*IMXLBRyPLewN-nmb419kNw.png)

---

## Tutorial

load packages

```python
from openai import OpenAI
# Text Splitting Utilities
from langchain.text_splitter import RecursiveCharacterTextSplitter, SentenceTransformersTokenTextSplitter
from sentence_transformers import CrossEncoder

import streamlit as st
from pypdf import PdfReader
import openai
import numpy as np
```

The cross-encoder 'ms-marco-MiniLM-L-6-v2' is used as a reranker to rank all text chunks against the user query. The top N most relevant text chunks will be used for answering user questions.

```ruby

st.set_page_config(page_title="PDF Query Assistant with Reranker and Completely Free", layout="wide")

def rank_doc(query, text_chunks, topN=5):
    # Initialize the CrossEncoder model with the specified model name
    reranker = CrossEncoder('cross-encoder/ms-marco-MiniLM-L-6-v2')

    # Predict scores for each document in relation to the query
    scores = reranker.predict([[query, doc] for doc in text_chunks])

    # Get indices of the top N scores in descending order
    top_indices = np.argsort(scores)[::-1][:topN]

    # Retrieve the top-ranked text documents using list indexing
    top_pairs = [text_chunks[index] for index in top_indices]
    return top_pairs  # Returns a list of the top-ranked text strings
```

The top N most relevant retrieved documents and the user query are used as input to GPT-4o to generate answers.

```python
def rag(query, retrieved_documents, api_key):
    model = "gpt-4o"


    # Set the API key
    openai.api_key = api_key

    information = "\n\n".join(retrieved_documents)
    messages = [
        {
            "role": "system",
            "content": "You are a helpful expert financial research assistant. Your users are asking questions about information contained in an annual 10K report."
                       "You will be shown the user's question, and the relevant information from the annual report. Answer the user's question using only this information."
        },
        {"role": "user", "content": f"Question: {query}. \n Information: {information}"}
    ]
    
    response = openai.chat.completions.create(
        model=model,
        messages=messages,
    )
    content = response.choices[0].message.content # Updated to correct attribute access
    return content
```

Text preprocessing steps include splitting PDF text and cleaning the text by removing special separators such as '\t' and '\n'. Streamlit caches the PDF processing step in memory to reduce latency.

```less
@st.cache_data
def process_pdf_texts(pdf_file):
    reader = PdfReader(pdf_file)
    pdf_texts = [p.extract_text().strip() for p in reader.pages if p.extract_text()]
    character_splitter = RecursiveCharacterTextSplitter(separators=["\n\n", "\n", ". ", " ", ""], chunk_size=1000, chunk_overlap=0)
    character_split_texts = character_splitter.split_text('\n\n'.join(pdf_texts))
    return clean_text_list(character_split_texts)

def clean_text_list(text_list):
    cleaned_texts = []
    for text in text_list:
        text = text.replace('\t', ' ').replace('\n', ' ')
        lines = [line.strip() for line in text.split('\n') if line.strip()]
        cleaned_text = '\n'.join(lines)
        cleaned_texts.append(cleaned_text)
    return cleaned_texts
```

Finally, a simple Streamlit interface is designed for users to input a passcode, upload a file, and ask questions.

```python
st.sidebar.title("Configuration")
api_key = st.sidebar.text_input("Enter your OpenAI API Key", type="password")
uploaded_file = st.sidebar.file_uploader("Choose a PDF file", type=['pdf'])

if uploaded_file and api_key:
    formatted_texts = process_pdf_texts(uploaded_file)
    st.session_state.processed_texts = formatted_texts

st.title("Free PDF Query Assistant with Reranker")
if 'chat_history' not in st.session_state:
    st.session_state.chat_history = []

if st.session_state.chat_history:
    for query, response in st.session_state.chat_history:
        st.container().markdown(f"**Q**: {query}")
        st.container().markdown(f"**A**: {response}")

query = st.text_input("Type your question here:", key="query")

if st.button("Submit Query"):
    if 'processed_texts' in st.session_state and query and api_key:
        with st.spinner('Processing...'):
            retrieved_documents = rank_doc(query, st.session_state.processed_texts)
            output_wrapped = rag(query, retrieved_documents, api_key)
            st.session_state.chat_history.append((query, output_wrapped))
            st.container().markdown(f"**Q**: {query}")
            st.container().markdown(f"**A**: {output_wrapped}")
    else:
        st.error("Please upload a PDF, ensure the API key is set, and type a question.")
```

Example Queries

```

    "Is tesla a good investment in 2024?",
    "Is Elon Musk a genius?",
    "What is the revenue for 2023?"
```

Example outputs

```
Answer for Q1
I'm sorry, but based on the information provided from the annual report
of Tesla, Inc. for the year ended December 31, 2023, I am unable to
provide a definitive answer on whether Tesla would be a good investment
in 2024. Investing decisions should take into account a variety of
factors beyond just financial statements, such as market conditions,
competition, industry trends, and overall economic outlook. It is
recommended that investors conduct thorough research and analysis or
consult with a financial advisor before making investment decisions.

Answer for Q2
The information provided does not directly give an opinion on whether
Elon Musk is a genius. The annual report outlines Elon Musk's role as
the Technoking of Tesla and the Chief Executive Officer, as well as his
involvement in other technology ventures. It highlights his significant
responsibilities and the potential impact on Tesla if he were to sell
shares or if his services were no longer available. However, the report
does not offer a definitive assessment regarding Elon Musk's genius.

Answer for Q3
The revenue for 2023 was $96.77 billion.
```

The answer is spot on. In our next article, we will evaluate different RAG pipelines to demonstrate a complete process for RAG model building, evaluation, and monitoring.

---

If you find this article helpful, please give it a clap (five times or more). Follow me on Medium, where I plan to routinely share my learnings. Feel free to share this article and leave your comments.

## References

> [**Mastering RAG: How to Select A Reranking Model - Galileo**](https://www.rungalileo.io/blog/mastering-rag-how-to-select-a-reranking-model)

[Github link](https://github.com/stanghong/RAG_Improvement/blob/main/reranker_GPT4o_Chatbot.py)