
![](https://miro.medium.com/1*GRL2Y2_2sJ9JGHv-Rc-5OA.jpeg)

We've discussed many advanced Retrieval Augmented Generation (RAG) retrieval strategies, each akin to a machine component. By combining these components in different ways, we can implement various RAG functionalities to meet different needs. Today, we will introduce some common RAG modules in advanced RAG retrieval and demonstrate how to combine these modules in a process-oriented way to achieve advanced RAG retrieval functions.

## RAG Modular

Modular RAG proposes a highly scalable paradigm that divides the RAG system into a three-layer structure of module types, modules, and operators. Each module type represents a core process within the RAG system, encompassing multiple functional modules. Each functional module, in turn, contains multiple specific operators. The entire RAG system becomes a combination of multiple modules and their corresponding operators, forming what we call the RAG flow. In this process, each module type can select different functional modules, and within each functional module, one or more operators can be selected.

![Image source: [https://medium.com/@yufan1602/modular-rag-and-rag-flow-part-%E2%85%B0-e69b32dc13a3](https://medium.com/@yufan1602/modular-rag-and-rag-flow-part-%E2%85%B0-e69b32dc13a3)](https://miro.medium.com/1*MD8CJ82H2zorWQuSNDuArg.jpeg)

## RAG Flow

The RAG flow refers to the entire working process within the RAG system, from the input query to the output generation of text. This process typically involves the coordinated work of multiple modules and operators, including but not limited to retrievers, generators, and possible pre-processing and post-processing modules. The design of the RAG flow aims to enable Large Language Models (LLMs) to utilize external knowledge bases or document sets when generating text, thereby improving the accuracy and relevance of responses.

The process of RAG inference generally follows these patterns:

- Sequential: Linear process, including both advanced and simple RAG paradigms

- Conditional: Choosing different RAG paths based on query keywords or semantics

- Branching: Including multiple parallel branches, divided into pre-retrieval and post-retrieval branches

- Loop: Including iterative, recursive, and adaptive retrieval structures

Below is a flowchart of the Loop mode in RAG:

![Image source: [https://medium.com/@yufan1602/modular-rag-and-rag-flow-part-ii-77b62bf8a5d3](https://medium.com/@yufan1602/modular-rag-and-rag-flow-part-ii-77b62bf8a5d3)](https://miro.medium.com/1*wqjAUrTKtvCuwALtZMkQKg.jpeg)

Next, we will primarily use the Sequential mode as an example to illustrate how to implement advanced RAG retrieval functions through modularization and pipelining.

## Code Example

LlamaIndex's query pipeline functionality provides a modular way to combine RAG retrieval strategies. By defining different modules and combining these modules in a certain order, we can form a complete query pipeline. Here, we will demonstrate how to use LlamaIndex's query pipeline feature to achieve advanced RAG retrieval through a simple to complex example.

## Basic RAG

First, we define a basic RAG pipeline that includes three modules: input, retrieval, and output. The input module is used to receive the user's query, the retrieval module is used to retrieve relevant documents from the knowledge base, and the output module is used to generate answers based on the retrieval results.

![](https://miro.medium.com/1*g-UbuhTYO0lLrQtU6Lzc4g.png)

Before defining the query pipeline, we need to index our test documents. Here, we use the movie plot of the [Avengers](https://en.wikipedia.org/wiki/Avenger) from Wikipedia as the test document. The sample code is as follows:

```python
import os
from llama_index.llms.openai import OpenAI
from llama_index.embeddings.openai import OpenAIEmbedding
from llama_index.core import (
    Settings,
    SimpleDirectoryReader,
    StorageContext,
    VectorStoreIndex,
    load_index_from_storage,
)
from llama_index.core.node_parser import SentenceSplitter

documents = SimpleDirectoryReader("./data").load_data()
node_parser = SentenceSplitter()
llm = OpenAI(model="gpt-3.5-turbo")
embed_model = OpenAIEmbedding(model="text-embedding-3-small")
Settings.llm = llm
Settings.embed_model = embed_model
Settings.node_parser = node_parser
if not os.path.exists("storage"):
    index = VectorStoreIndex.from_documents(documents)
    index.set_index_id("avengers")
    index.storage_context.persist("./storage")
else:
    store_context = StorageContext.from_defaults(persist_dir="./storage")
    index = load_index_from_storage(
        storage_context=store_context, index_id="avengers"
    )
```

- First, we use `SimpleDirectoryReader` to read documents from the `./data` directory.

- Then, we define a `SentenceSplitter` to split the document into sentences.

- We use OpenAI's LLM and Embedding model to generate text and vectors and add them to `Settings`.

- Finally, we index the documents and save the index to the `./storage` directory for future use.

Next, we define a basic RAG pipeline. The sample code is as follows:

```python
from llama_index.core.query_pipeline import QueryPipeline, InputComponent
from llama_index.core.response_synthesizers.simple_summarize import SimpleSummarize

retriever =  index.as_retriever()
p = QueryPipeline(verbose=True)
p.add_modules(
    {
        "input": InputComponent(),
        "retriever": retriever,
        "output": SimpleSummarize(),
    }
)
p.add_link("input", "retriever")
p.add_link("input", "output", dest_key="query_str")
p.add_link("retriever", "output", dest_key="nodes")
```

- We create a basic retriever `retriever` to retrieve relevant documents from the knowledge base.

- Then, we create a `QueryPipeline` object, which is the main body of the query pipeline, with the verbose parameter set to True for detailed output.

- We add three modules using the `add_modules` method of `QueryPipeline`: `input`, `retriever`, and `output`.

- The `input` module's implementation class is `InputComponent`, a common input component for query pipelines. The `retriever` module is our defined retriever, and the `output` module's implementation class is `SimpleSummarize`, which summarizes the question and retrieval results.

- We then add links between the modules using the `add_link` method. The first parameter is the source module, and the second parameter is the destination module.

- The `dest_key` parameter specifies the input parameter of the destination module. Since the output module has two parameters (query and retrieval result), we need to specify the `dest_key` parameter. If the destination module has only one parameter, we don't need to specify it.

- In the `add_link` method, the `src_key` parameter corresponds to the `dest_key` parameter. When the source module has multiple parameters, we need to specify the `src_key` parameter; otherwise, we don't need to.

In addition to the `add_modules` and `add_link` methods, modules and link relationships can also be added using the `add_chain` method. The sample code is as follows:

```python
p = QueryPipeline(verbose=True)
p.add_chain([InputComponent(), retriever])
```

This method allows adding modules and link relationships in one go, but it can only add single-parameter modules. If a module has multiple parameters, we need to use the `add_modules` and `add_link` methods.

Next, we run the query pipeline. The sample code is as follows:

```python
question = "Which two members of the Avengers created Ultron?"
output = p.run(input=question)
print(str(output))

# Output
> Running module input with input:
input: Which two members of the Avengers created Ultron?

> Running module retriever with input:
input: Which two members of the Avengers created Ultron?

> Running module output with input:
query_str: Which two members of the Avengers created Ultron?
nodes: [NodeWithScore(node=TextNode(id_='53d32f3a-a2d5-47b1-aa8f-a9679e83e0b0', embedding=None, metadata={'file_path': '/data/Avengers:Age-of-Ul...

Bruce Banner and Tony Stark.
```

- We use the `run` method of the query pipeline to run the query pipeline, passing the question as an input parameter.

- The result shows the debug information of the query pipeline. The query pipeline first runs the `input` module, then the `retriever` module, and finally the `output` module. The debug information also prints the input parameters of each module and outputs the answer to the question.

## Adding a Reranker Module

Next, we add a reranker module to the basic RAG to reorder the retrieval results.

![](https://miro.medium.com/1*uTFU7JPJ50FcCM-8f_Bdow.png)

```diff
+from llama_index.postprocessor.cohere_rerank import CohereRerank

+reranker = CohereRerank()
p = QueryPipeline(verbose=True)
p.add_modules(
    {
        "input": InputComponent(),
        "retriever": retriever,
+        "reranker": reranker,
        "output": SimpleSummarize(),
    }
)
p.add_link("input", "retriever")
+p.add_link("input", "reranker", dest_key="query_str")
+p.add_link("retriever", "reranker", dest_key="nodes")
p.add_link("input", "output", dest_key="query_str")
-p.add_link("retriever", "output", dest_key="nodes")
+p.add_link("reranker", "output", dest_key="nodes")
```

- Here, we use the rerank feature from [Cohere](https://cohere.com/). LlamaIndex provides the `CohereRerank` class to implement Cohere's rerank functionality.

- To use the `CohereRerank` class, you need to register an account on Cohere's official website, obtain an API KEY, and set the `COHERE_API_KEY` value in the environment variable: `export COHERE_API_KEY=your-cohere-api-key`.

- We then add a `reranker` module to the query pipeline, placing it between the `retriever` module and the `output` module to reorder the retrieval results.

- We remove the original link from the `retriever` module to the `output` module and add links from the `retriever` module to the `reranker` module and from the `reranker` module to the `output` module.

- The `reranker` module also requires two parameters: the question and the retrieval result, so we need to specify the `dest_key` parameter.

Besides the `run` method, the query pipeline also has a `run_with_intermediates` method, which can get the intermediate results of the pipeline. We print the intermediate results of the `retriever` and `reranker` modules for comparison. The sample code is as follows:

```python
output, intermediates = p.run_with_intermediates(input=question)
retriever_output = intermediates["retriever"].outputs["output"]
print(f"retriever output:")
for node in retriever_output:
    print(f"node id: {node.node_id}, node score: {node.score}")
reranker_output = intermediates["reranker"].outputs["nodes"]
print(f"\nreranker output:")
for node in reranker_output:
      print(f"node id: {node.node_id}, node score: {node.score}")

# Output
retriever output:
node id: 53d32f3a-a2d5-47b1-aa8f-a9679e83e0b0, node score: 0.6608391314791646
node id: dea3844b-789f-46de-a415-df1ef14dda18, node score: 0.5313643379538727
reranker output:
node id: 53d32f3a-a2d5-47b1-aa8f-a9679e83e0b0, node score: 0.9588471
node id: dea3844b-789f-46de-a415-df1ef14dda18, node score: 0.5837967
```

- After executing the `run_with_intermediates` method, the returned result is a tuple containing the output and intermediate results.

- To get the intermediate results of a module, use the `intermediates` variable plus the module key. For example, `intermediates["retriever"]` gets the intermediate result of the retrieval module.

- Each intermediate result has two parameters: `inputs` and `outputs`. `inputs` represent the input parameters of the module, and `outputs` represent the output parameters of the module.

- The `inputs` and `outputs` parameters are dictionaries. For example, the `outputs` parameter of the `reranker` module contains the `nodes` attribute. We can get the value of the `nodes` attribute as follows: `intermediates["reranker"].outputs["nodes"]`.

## Adding a Query Rewrite Module

Previously, we added a reranker module to the query pipeline, which is a post-processing operation on the retrieval results. Now, we will add a query rewrite module to perform pre-processing on the query.

![](https://miro.medium.com/1*A-SsFRkKDSOtB874WuowuA.png)

```diff
+query_rewriter = HydeComponent()
p = QueryPipeline(verbose=True)
p.add_modules(
    {
        "input": InputComponent(),
+        "query_rewriter": query_rewriter,
        "retriever": retriever,
        "reranker": reranker,
        "output": SimpleSummarize(),
    }
)

-p.add_link("input", "retriever")
+p.add_link("input", "query_rewriter")
+p.add_link("query_rewriter", "retriever")
p.add_link("input", "reranker", dest_key="query_str")
p.add_link("retriever", "reranker", dest_key="nodes")
p.add_link("input", "output", dest_key="query_str")
p.add_link("reranker", "output", dest_key="nodes")
```

- Here, we define a `HydeComponent` class to implement the query rewrite functionality using the HyDE (Hypothetical Document Embedding) query rewrite strategy. It generates a hypothetical answer based on the query and then uses this hypothetical answer to retrieve documents, improving retrieval accuracy.

- `HydeComponent` is a custom query pipeline component, which we will explain in detail later.

- We add a `query_rewriter` module to the query pipeline, placing it between the `input` and `retriever` modules to pre-process the query.

- We remove the original link from the `input` module to the `retriever` module and add links from the `input` module to the `query_rewriter` module and from the `query_rewriter` module to the `retriever` module.

- The `query_rewriter` module has only one parameter, so we don't need to specify the `dest_key` parameter.

LlamaIndex's query pipeline provides the functionality to create custom components. By inheriting the `CustomQueryComponent` class, we can implement custom components. Below is the implementation of the `HydeComponent` class:

```python
from llama_index.core.query_pipeline import CustomQueryComponent
from typing import Dict, Any
from llama_index.core.indices.query.query_transform import HyDEQueryTransform

class HydeComponent(CustomQueryComponent):
    """HyDE query rewrite component."""
    def _validate_component_inputs(self, input: Dict[str, Any]) -> Dict[str, Any]:
        """Validate component inputs during run_component."""
        assert "input" in input, "input is required"
        return input

    @property
    def _input_keys(self) -> set:
        """Input keys dict."""
        return {"input"}

    @property
    def _output_keys(self) -> set:
        return {"output"}

    def _run_component(self, **kwargs) -> Dict[str, Any]:
        """Run the component."""
        hyde = HyDEQueryTransform(include_original=True)
        query_bundle = hyde(kwargs["input"])
        return {"output": query_bundle.embedding_strs[0]}
```

- The `_validate_component_inputs` method in the `HydeComponent` class validates the component's input parameters. This method must be implemented; otherwise, an exception will be thrown.

- The `_input_keys` and `_output_keys` properties define the input and output keys for the component.

- The `_run_component` method implements the specific functionality of the component. Here, we use the `HyDEQueryTransform` class to implement the HyDE query rewrite functionality, converting the query into a hypothetical answer and returning this hypothetical answer.

For more query rewrite strategies, refer to my previous article.

> [**Advanced RAG Retrieval Strategy: Query Rewriting**](https://generativeai.pub/advanced-rag-retrieval-strategy-query-rewriting-a1dd61815ff0)

## Replacing the Output Module

In the previous query pipeline, we used a simple summarize output component. Now, we will replace it with a tree summarize component to improve the final output result.

> _The tree summarize component recursively merges and summarizes text blocks in a bottom-up manner (i.e., building a tree from leaf to root). Specifically, in each recursive step: 1._ We repackage the text blocks so that each block fills the LLM's context window. 2. If there is only one block, we provide the final response. 3. Otherwise, we summarize each block and recursively summarize these summaries.

![](https://miro.medium.com/1*z2abVNM-jRuOH1JT_7G9gw.png)

```diff
+from llama_index.core.response_synthesizers.tree_summarize import TreeSummarize

p = QueryPipeline(verbose=True)
p.add_modules(
    {
        "input": InputComponent(),
        "query_rewriter": query_rewriter,
        "retriever": retriever,
        "reranker": reranker,
-        "output": SimpleSummarize(),
+        "output": TreeSummarize(),
    }
)
```

- Replacing the `output` module's component is relatively simple. We only need to replace the original `SimpleSummarize` with `TreeSummarize`.

- The structure of the `TreeSummarize` component is similar to the `SimpleSummarize` component, so we don't need to modify other module connections.

The query pipeline is essentially a DAG (Directed Acyclic Graph). Each module is a node in the graph, and the connections between modules are the edges. We can use code to visualize this graph structure. The sample code is as follows:

```python
from pyvis.network import Network

net = Network(notebook=True, cdn_resources="in_line", directed=True)
net.from_nx(p.clean_dag)
net.write_html("output/pipeline_dag.html")
```

- We use the `pyvis` library to draw the query pipeline's graph structure.

- The `Network` class is used to create a network object. `notebook=True` means to display in Jupyter Notebook, `cdn_resources="in_line"` means to use inline resources, and `directed=True` means a directed graph.

- The `from_nx` method converts the query pipeline's DAG structure into a network object.

- The `write_html` method saves the network object as an HTML file, allowing us to view the query pipeline's graph structure in a browser.

The saved query pipeline graph structure is as follows:

![](https://miro.medium.com/1*Wg5EVj0hsNFxBpPz8vaCbg.png)

## Using Sentence Window Retrieval

In the previous query pipeline, the `retriever` module used a basic retrieval strategy. Now, we will replace it with a sentence window retrieval strategy to improve retrieval accuracy.

> _The principle of sentence window retrieval: First, when segmenting the document, it is split into sentences and embedded into the database. During retrieval, relevant sentences are retrieved, but not just the retrieved sentences are used as the retrieval result. Instead, the sentences before and after the retrieved sentence are included, and the number of sentences included can be set via parameters. Finally, the retrieval results are submitted to the LLM to generate the answer._

![](https://miro.medium.com/1*GGRBv_K5tnUMk9sqrwkLyw.png)

```diff
+from llama_index.core.node_parser import SentenceWindowNodeParser
+from llama_index.core.indices.postprocessor import MetadataReplacementPostProcessor

-node_parser = SentenceSplitter()
+node_parser = SentenceWindowNodeParser.from_defaults(
+    window_size=3,
+    window_metadata_key="window",
+    original_text_metadata_key="original_text",
+)
+meta_replacer = MetadataReplacementPostProcessor(target_metadata_key="window")
p = QueryPipeline(verbose=True)
p.add_modules(
    {
        "input": InputComponent(),
        "query_rewriter": query_rewriter,
        "retriever": retriever,
+        "meta_replacer": meta_replacer,
        "reranker": reranker,
        "output": TreeSummarize(),
    }
)
p.add_link("input", "query_rewriter")
p.add_link("query_rewriter", "retriever")
+p.add_link("retriever", "meta_replacer")
p.add_link("input", "reranker", dest_key="query_str")
-p.add_link("retriever", "reranker", dest_key="nodes")
+p.add_link("meta_replacer", "reranker", dest_key="nodes")
p.add_link("input", "output", dest_key="query_str")
p.add_link("reranker", "output", dest_key="nodes")
```

- Sentence window retrieval first requires adjusting the document indexing strategy. Previously, `SentenceSplitter` was used to split the document. Now, we use `SentenceWindowNodeParser` to split the document, with a window size of 3. The key for the original text is `original_text`, and the key for the window text is `window`.

- The principle of sentence window retrieval is to replace the node text in the retrieval results with window text after retrieval. So we need to add a `meta_replacer` module to replace the node text in the retrieval results.

- The implementation class of the `meta_replacer` module is `MetadataReplacementPostProcessor`. The input parameter is the retrieval result `nodes`, and the output result is the retrieval result `nodes` with replaced node text.

- We place the `meta_replacer` module between the `retriever` and `reranker` modules to perform metadata replacement processing on the retrieval results before performing rerank operations. Therefore, we modify the connection relationships of these three modules.

We can print the intermediate results of the `retriever` and `meta_replacer` modules to compare the changes in the retrieval results. The sample code is as follows:

```python
output, intermediates = p.run_with_intermediates(input=question)
retriever_output = intermediates["retriever"].outputs["output"]
print(f"retriever output:")
for node in retriever_output:
    print(f"node: {node.text}\n")
meta_replacer_output = intermediates["meta_replacer"].outputs["nodes"]
print(f"meta_replacer output:")
for node in meta_replacer_output:
    print(f"node: {node.text}\n")

# Output
retriever output:
node: In the Eastern European country of Sokovia, the Avengers-Tony Stark, Thor, Bruce Banner, Steve Rogers, Natasha Romanoff, and Clint Barton-raid a Hydra facility commanded by Baron Wolfgang von Strucker, who has experimented on humans using the scepter previously wielded by Loki.
node: They meet two of Strucker's test subjects-twins Pietro (who has superhuman speed) and Wanda Maximoff (who has telepathic and telekinetic abilities)-and apprehend Strucker, while Stark retrieves Loki's scepter.
meta_replacer output:

node: and attacks the Avengers at their headquarters.  Escaping with the scepter, Ultron uses the resources in Strucker's Sokovia base to upgrade his rudimentary body and build an army of robot drones.  Having killed Strucker, he recruits the Maximoffs, who hold Stark responsible for their parents' deaths by his company's weapons, and goes to the base of arms dealer Ulysses Klaue in Johannesburg to get vibranium.  The Avengers attack Ultron and the Maximoffs, but Wanda subdues them with haunting visions, causing Banner to turn into the Hulk and rampage until Stark stops him with his anti-Hulk armor. [a]
A worldwide backlash over the resulting destruction, and the fears Wanda's hallucinations incited, send the team into hiding at Barton's farmhouse.  Thor departs to consult with Dr.  Erik Selvig on the apocalyptic future he saw in his hallucination, while Nick Fury arrives and encourages the team to form a plan to stop Ultron.
node: In the Eastern European country of Sokovia, the Avengers-Tony Stark, Thor, Bruce Banner, Steve Rogers, Natasha Romanoff, and Clint Barton-raid a Hydra facility commanded by Baron Wolfgang von Strucker, who has experimented on humans using the scepter previously wielded by Loki.  They meet two of Strucker's test subjects-twins Pietro (who has superhuman speed) and Wanda Maximoff (who has telepathic and telekinetic abilities)-and apprehend Strucker, while Stark retrieves Loki's scepter.
Stark and Banner discover an artificial intelligence within the scepter's gem, and secretly decide to use it to complete Stark's "Ultron" global defense program.  The unexpectedly sentient Ultron, believing he must eradicate humanity to save Earth, eliminates Stark's A.I.
```

From the results, we can see that the original `retriever` module output only a simple sentence, while the `meta_replacer` module output multiple sentences, including the text of the retrieved node's preceding and following nodes, allowing the LLM to generate more accurate answers.

For more details on sentence window retrieval, refer to my previous article.

> [**Advanced RAG Retrieval Strategies: Sentence Window Retrieval**](https://generativeai.pub/advanced-rag-retrieval-strategies-sentence-window-retrieval-b6964b6e56f7)

## Adding an Evaluation Module

Finally, we add an evaluation module to the query pipeline to evaluate the query pipeline. Here, we use [Ragas](https://docs.ragas.io/) to implement the evaluation module.

> _Ragas is a framework for evaluating RAG applications, offering many detailed evaluation metrics._

![](https://miro.medium.com/1*MmJhxERzKMs4TZbqvdYgJw.png)

```diff
+evaluator = RagasComponent()
p = QueryPipeline(verbose=True)
p.add_modules(
    {
        "input": InputComponent(),
        "query_rewriter": query_rewriter,
        "retriever": retriever,
        "meta_replacer": meta_replacer,
        "reranker": reranker,
        "output": TreeSummarize(),
+        "evaluator": evaluator,
    }
)
-p.add_link("input", "query_rewriter")
+p.add_link("input", "query_rewriter", src_key="input")
p.add_link("query_rewriter", "retriever")
p.add_link("retriever", "meta_replacer")
-p.add_link("input", "reranker", dest_key="query_str")
+p.add_link("input", "reranker", src_key="input", dest_key="query_str")
p.add_link("meta_replacer", "reranker", dest_key="nodes")
-p.add_link("input", "output", dest_key="query_str")
+p.add_link("input", "output", src_key="input", dest_key="query_str")
p.add_link("reranker", "output", dest_key="nodes")
+p.add_link("input", "evaluator", src_key="input", dest_key="question")
+p.add_link("input", "evaluator", src_key="ground_truth", dest_key="ground_truth")
+p.add_link("reranker", "evaluator", dest_key="nodes")
+p.add_link("output", "evaluator", dest_key="answer")
```

- `RagasComponent` is also a custom query pipeline component, which we will explain in detail later.

- We add an `evaluator` module to the query pipeline to evaluate the query pipeline.

- We place the `evaluator` module after the `output` module to evaluate the output results.

- The `evaluator` module has four input parameters: the question, the ground truth, the retrieval result, and the generated answer. The question and ground truth are passed through the `input` module, the retrieval result is passed through the `reranker` module, and the generated answer is passed through the `output` module.

- Since the `input` module now has two parameters (the question `input` and the ground truth `ground_truth`), we need to specify the `src_key` parameter when adding the connections related to the `input` module.

Let's look at the implementation of the `RagasComponent` class. The sample code is as follows:

```python
from ragas.metrics import faithfulness, answer_relevancy, context_precision, context_recall
from ragas import evaluate
from datasets import Dataset
from llama_index.core.query_pipeline import CustomQueryComponent
from typing import Dict, Any

metrics = [faithfulness, answer_relevancy, context_precision, context_recall]

class RagasComponent(CustomQueryComponent):
    """Ragas evaluation component."""
    def _validate_component_inputs(self, input: Dict[str, Any]) -> Dict[str, Any]:
        """Validate component inputs during run_component."""
        return input
    
    @property
    def _input_keys(self) -> set:
        """Input keys dict."""
        return {"question", "nodes", "answer", "ground_truth", }

    @property
    def _output_keys(self) -> set:
        return {"answer", "source_nodes", "evaluation"}

    def _run_component(self, **kwargs) -> Dict[str, Any]:
        """Run the component."""
        question, ground_truth, nodes, answer = kwargs.values()
        data = {
            "question": [question],
            "contexts": [[n.get_content() for n in nodes]],
            "answer": [str(answer)],
            "ground_truth": [ground_truth],
        }
        dataset = Dataset.from_dict(data)
        evaluation = evaluate(dataset, metrics)
        return {"answer": str(answer), "source_nodes": nodes, "evaluation": evaluation}
```

- Similar to previous custom components, the `RagasComponent` class needs to implement the `_validate_component_inputs`, `_input_keys`, `_output_keys`, and `_run_component` methods.

- The input parameters for the component are the question, ground truth, retrieval result, and generated answer. The output parameters are the generated answer, retrieval result, and evaluation result.

- In the `_run_component` method, we repackage the input parameters into a `Dataset` object suitable for Ragas evaluation.

- The evaluation metrics we use are: `faithfulness` (evaluating the consistency between `Question` and `Context`), `answer_relevancy` (evaluating the consistency between `Answer` and `Question`), `context_precision` (evaluating whether `Ground Truth` ranks high in `Context`), and `context_recall` (evaluating the consistency between `Ground Truth` and `Context`).

- We then call the `evaluate` method to evaluate the `Dataset` object and obtain the evaluation result.

- Finally, we return the generated answer, retrieval result, and evaluation result.

Finally, we run the query pipeline. The sample code is as follows:

```python
question = "Which two members of the Avengers created Ultron?"
ground_truth = "Tony Stark (Iron Man) and Bruce Banner (The Hulk)."
output = p.run(input=question, ground_truth=ground_truth)
print(f"answer: {output['answer']}")
print(f"evaluation: {output['evaluation']}")

# Output
answer: Tony Stark and Bruce Banner
evaluation: {'faithfulness': 1.0000, 'answer_relevancy': 0.8793, 'context_precision': 1.0000, 'context_recall': 1.0000}
```

- When running the query pipeline, we need to pass the question and ground truth as input parameters.

- In the output, we can see the generated answer and the evaluation results with four evaluation metrics.

For more RAG evaluation tools, refer to my previous article.

> [**LlamaIndex and RAG Evaluation Tools**](https://generativeai.pub/llamaindex-and-rag-evaluation-tools-59bae2944bb3)

## Summary

Through the above examples, we have shown how to implement advanced RAG retrieval functions using modular and process-oriented methods. Depending on specific needs, we can customize different modules and combine these modules in a certain order to form a complete query pipeline. In RAG applications, we can also define multiple query pipelines for different scenarios such as Q&A, dialogue, and recommendation, better meeting various needs.

Follow me to learn about various new AI and AIGC technologies. Feel free to exchange ideas, and if you have any questions or comments, please leave them in the comment section.

## References

- [Modular RAG and RAG Flow: Part Ⅰ](https://medium.com/@yufan1602/modular-rag-and-rag-flow-part-%E2%85%B0-e69b32dc13a3)

- [Modular RAG and RAG Flow: Part II](https://medium.com/@yufan1602/modular-rag-and-rag-flow-part-ii-77b62bf8a5d3)

- [An Introduction to LlamaIndex Query Pipelines](https://docs.llamaindex.ai/en/stable/examples/pipeline/query_pipeline/)