In this post, we will Create an Autonomous AI Agent With Python from Scratch.

We will **NOT** use any third-party libraries like Langchain or CrewAI; we will use **pure Python!**

![](https://miro.medium.com/1*H8E6hlsijtZqwpYWO6ittw.png)

We will go with a very basic AI Agent example that helps you understand the basic structure and development process of AI agents.

## What is an AI Agent?

If we ask an AI like ChatGPT: _**What is the response time for learnwithhasan.com?**_

**Do you think it can answer it?**

If you said NO, you are right.

and if you said YES, you are also right!

Interestingly, both answers could be considered correct. Here's why:

Here is ChatGPT's Answer to the question:

![](https://miro.medium.com/0*x_sl66rTqcjJTLOw.png)

**It was not able to answer**!

As we learned in _**[prompting engineering](https://learnwithhasan.com/learn/prompt-engineering/)**_, one of the main limitations of LLMs is that it can't access Realtime data, **it only generates responses based solely on pre-existing training data.**

However, look at this now:

![](https://miro.medium.com/0*VVig-CmVsNIV2KE3.png)

**What happened** ?!

Answer: **Autonomous AI Agents** 💪

An Autonomous AI Agent integrates a **large language model** (LLM) with **external functions** and **enhanced prompting** mechanisms.

![](https://miro.medium.com/0*8ly5BvBYP3tjmwv_.png)

To understand the concept, let's see how the LLM was able to answer our question.

![](https://miro.medium.com/0*glu4xLlTyki0iFBN.png)

**1- Query Input:** First, we send our question to the LLM.

**2- Processing with ReAct System Prompt**: The LLM is Powered by a **ReAct System Prompt** that allows it to think about the question and how it should answer it. we call this a Thought, _we will discuss this more in the next sections._

**3- External Function Execution:** The LLM then selects and executes an external function, in this case, "_**get_website_response_time(url)**_."

4- **Response Generation:** Having obtained the real-time data, the AI crafts and delivers a response based on the result.

---

## Getting Started

In this guide, we're going to build AI agents from scratch using Python. Let's start by setting up a **new Python project.**

You can choose any IDE, but for this guide, I'll be using [Visual Studio Code](https://code.visualstudio.com/Download).

### Create and Activate a Virtual Environment

- Open your terminal.

- Create a new virtual environment and activate it.

![](https://miro.medium.com/0*AlXKgTdAQ4H48FWU.png)

### Install the OpenAI Package

For this example, we'll be using the [OpenAI API](https://openai.com/) as our large language model, although you could alternatively use models from _Anthropic_, _Gemini_, or even open-source models.

Ensure your API key is ready. Create a `.env` file in your project and add your key like so

```ini
OPENAI_API_KEY = "sk-XX"
```

With the virtual environment active, install the OpenAI Python package:

```typescript
pip install openai
```

Done? Great ✅

### Set Up Your Project Files

Create three Python files: `actions.py`, `prompts.py`, and `main.py`.

You should have now something like this:

![](https://miro.medium.com/0*ovYpawDVgqQSKmPJ.png)

### Generate Text with OpenAI API

Open the `main.py` file and create a simple function to generate text using the OpenAI API. This function will power our AI agent:

**Here is the code:**

```python
from openai import OpenAI
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Create an instance of the OpenAI class
openai_client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))


def generate_text_with_conversation(messages, model = "gpt-3.5-turbo"):
    response = openai_client.chat.completions.create(
        model=model,
        messages=messages
        )
    return response.choices[0].message.content
```

This script loads your API key from the `.env` file and creates an instance of `OpenAI` to handle requests.

The `generate_text_with_conversation` function is straightforward, taking two parameters—`model` and `messages`—to generate a response.

### Test Your Function

Before moving on, let's ensure everything is working as expected. Test the function by simulating a conversation:

# Define a list of messages to simulate a conversation

```makefile
# Define a list of messages to simulate a conversation
test_messages = [
    {"role": "user", "content": "Hello, how are you?"},
    {"role": "system", "content": "You are a helpful AI assistant"}
]
# Call the function with the test messages
response = generate_text_with_conversation(test_messages)
print("AI Response:", response)
```

Done? Perfect! ✅

Now that our basic setup is complete, we're ready to move on to the core parts of building our agent.

---

## Define the Functions

In this part of the guide, we will specify the actions or functions that our AI agent can access. This enables the agent to utilize external functionalities when responding to user queries.

### Create Basic Functionality

Open the `actions.py` file. Here, we'll define a simple function to simulate response times for different websites:

```python
def get_response_time(url):
    if url == "learnwithhasan.com":
        return 0.5
    if url == "google.com":
        return 0.3
    if url == "openai.com":
        return 0.4
```

This dummy function returns fixed response times based on the provided URL. It serves as a basic example to help us understand how the agent can utilize external functions.

---

## The ReAct Prompt

The ReAct Prompt is what enables our AI agent to mimic human behavior.

This system prompt guides the model through a cycle of Thought, Action, and Response, allowing it to handle user queries effectively.

To put simply, the ReAct prompt instructs the model to think about the user query, understand it, decide how to answer, pick an action if needed, then use this to answer the question in the best way it can.

Let me share the prompt, then I'll explain.

### Define the ReAct Prompt

In the `prompts.py` file, add the following system prompt configuration:

```python
system_prompt = """

You run in a loop of Thought, Action, PAUSE, Action_Response.
At the end of the loop you output an Answer.

Use Thought to understand the question you have been asked.
Use Action to run one of the actions available to you - then return PAUSE.
Action_Response will be the result of running those actions.

Your available actions are:

get_response_time:
e.g. get_response_time: learnwithhasan.com
Returns the response time of a website

Example session:

Question: what is the response time for learnwithhasan.com?
Thought: I should check the response time for the web page first.
Action: 

{
  "function_name": "get_response_time",
  "function_parms": {
    "url": "learnwithhasan.com"
  }
}

PAUSE

You will be called again with this:

Action_Response: 0.5

You then output:

Answer: The response time for learnwithhasan.com is 0.5 seconds.
"""
```

This system prompt instructs the LLM to run within a loop of Thought, Action, and Action_Response.

The loop structure (Thought, Action, PAUSE, Action_Response) guides the LLM:

- **Thought:** Understand and interpret the query.

- **Action:** Select and execute the appropriate function from the available actions.

- **Action_Response:** Use the result from the action to formulate the response.

### Available actions

Then we tell the LLM what actions are available, showing a simple example with the parameter and a simple description for the model to know what the function is about.

```sql
Your available actions are:
get_response_time:
e.g. get_response_time: learnwithhasan.com
Returns the response time of a website
```

💡 **Make sure to match the function name with the one your defined in python.**

### Example session

Then we show the LLM an example on how it will act to answer a sample query.

The most important part here is how it will **return the Action:**

```css
Action: 
{
  "function_name": "get_response_time",
  "function_parms": {
    "url": "learnwithhasan.com"
  }
}
```

You can see here, I instructed the LLM to return the action in a **[JSON Format](https://learnwithhasan.com/consistent-json-gemini-python/)**.

This will help us later work with functions and run them as you will in the last part when we put things together.

### Why a Loop?

This looping mechanism mimics the steps an LLM takes: understanding the question, taking an action based on that understanding, and using the outcome of the action to respond.

This process can range from a couple of loops for simple tasks to potentially hundreds for more complex scenarios.

---

## Putting Things Together

Having established the ReAct System Prompt and defined the necessary functions, we can now integrate these elements to construct our AI agent.

Let's return to our `main.py` script to complete the setup.

### Define Available Functions

First, list the functions the agent can utilize. For this example, we only have one:

```python
available_actions = {
    "get_response_time": get_response_time
}
```

In our case we have one function only.

This will enable the agent to select the correct function efficiently.

### Set Up User and System Prompts

Define the user prompt and the messages that will be passed to the `generate_text_with_conversation` function we previously created:

```python
user_prompt = "What is the response time for learnwithhasan.com?"

messages = [
    {"role": "system", "content": system_prompt},
    {"role": "user", "content": user_prompt},
]
```

The system prompt, structured as a ReAct loop directive, is provided as a system message to the OpenAI LLM.

Now OpenAI's LLM Model will be instructed to act in a loop of Though. Action, and Action Result!

### Create the Agentic Loop

Implement the loop that processes user inputs and handles AI responses:

```python
turn_count = 1
max_turns = 5


while turn_count < max_turns:
    print (f"Loop: {turn_count}")
    print("----------------------")
    turn_count += 1

    response = generate_text_with_conversation(messages, model="gpt-4")

    print(response)

    json_function = extract_json(response)

    if json_function:
            function_name = json_function[0]['function_name']
            function_parms = json_function[0]['function_parms']
            if function_name not in available_actions:
                raise Exception(f"Unknown action: {function_name}: {function_parms}")
            print(f" -- running {function_name} {function_parms}")
            action_function = available_actions[function_name]
            #call the function
            result = action_function(**function_parms)
            function_result_message = f"Action_Response: {result}"
            messages.append({"role": "user", "content": function_result_message})
            print(function_result_message)
    else:
         break
```

This loop reflects the ReAct cycle, generating responses, extracting JSON-formatted function calls, and executing the appropriate actions.

So we generate the response, and we check if the LLM returned a function.

I created the _**extract_json**_ method to make it easy for your to extract any functions from the LLM response.

In the following line:

```python
json_function = extract_json(response)
```

We will check if the LLM returned a function to execute, if yes, it will execute and append the result to the messages, so in the next turn, the LLM can use the Action_response to asnwer the user query.

### Test the Agent!

To see this agent in action, you can download the complete codebase using the link provided below:

**[Basic AI Agent Code](https://learnwithhasan.com/custom-code/ai-agent-guide-source-code/)**

And if you like to see all this in action and see another Real-world Agent Example, you can check this free video:

<iframe src="https://cdn.embedly.com/widgets/media.html?src=https%3A%2F%2Fwww.youtube.com%2Fembed%2FcDm5vPXVln8%3Ffeature%3Doembed&display_name=YouTube&url=https%3A%2F%2Fwww.youtube.com%2Fwatch%3Fv%3DcDm5vPXVln8&image=https%3A%2F%2Fi.ytimg.com%2Fvi%2FcDm5vPXVln8%2Fhqdefault.jpg&key=a19fcc184b9711e1b4764040d3dc5c07&type=text%2Fhtml&schema=youtube" title="" height="480" width="854"></iframe>

For more in-depth exploration and additional examples, consider checking out my full course, "**[Build AI Agents From Scratch With Python](https://learnwithhasan.com/learn/build-ai-agents/)**."

And remember, If you have any questions or any encounter issues, I'm available nearly every day on **[the forum](https://learnwithhasan.com/community/)** to assist you - for free!