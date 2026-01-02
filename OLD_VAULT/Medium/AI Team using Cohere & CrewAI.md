
![ChatGPT Vision](https://miro.medium.com/0*jtNA3kgeNVFBSdHV)

## Introduction

As generative AI reshapes our interaction with technology, CrewAI emerges as a beacon of innovation. This narrative begins with my journey leveraging [crewAI - Multi AI Agents systems.](https://www.crewai.io/) alongside [Cohere's Chat model](https://cohere.com/) to automate complex tasks, transcending traditional skill boundaries.

My exploration with [Databutton](https://www.databutton.io/), an intuitive platform for crafting AI-driven applications through conversation, unveils the untapped potential of generative AI Agents. Databutton democratizes AI development, erasing the daunting barriers of coding, and empowers creators to forge powerful, data-driven solutions. This journey is not just about automation; it's about unlocking creativity and making impactful AI accessible to all.

> "Great ideas could and should come from everywhere. We're making it possible for anyone to succeed in making real world impact with AI." - Databutton

Continue reading to discover how I leveraged AI to assist in my work and to see the final output, emphasizing that while AI plays a supportive role, the human element remains crucial. These AI agents accelerate our knowledge work, allowing us to concentrate on creating more value. My ambition is to showcase how this technology can empower charity organizations, driving innovation and efficiency, and enabling them to deliver greater value to their communities.

Let's dive in!

## **The Evolution of Prompting**

As we explore the advancements in AI's capability to understand and interact with us, it's helpful to trace the evolution of how we communicate with these intelligent systems. From the initial days of command-based prompts to the nuanced and adaptive approaches of today, each stage in the development of prompting technology has brought us closer to creating AI that can reason, understand context, and even take initiative. This journey highlights a significant shift towards AI models that not only follow instructions but also engage in meaningful, dynamic dialogues, mirroring human cognitive processes more closely than ever before.

1. **Command-Based Prompts:** Initial AI models required direct, explicit instructions for performing specific tasks, lacking flexibility and understanding.

2. **Natural Language Understanding (NLU):** AI advanced to interpret complex, human-like prompts, allowing for more nuanced interactions.

3. **Contextual and Dynamic Prompting:** Models gained the ability to adjust responses based on ongoing dialogues, enhancing conversation continuity.

4. **Chain-of-Thought (CoT) Prompting:** AIs began simulating logical reasoning processes for more complex problem-solving, improving interpretability.

5. **ReAct Prompting:** The latest evolution combines reasoning with the capability to fetch external information, significantly enhancing AI problem-solving and adaptability.

These milestones illustrate the journey towards AI that more closely mimics human cognitive abilities, marking progress from simple instruction-following to complex, dynamic problem-solving and reasoning.

## What Exactly is ReACT Prompting?

Diving into the cutting-edge of AI interaction, ReACT prompting stands as a significant leap forward. This innovative approach marries the processes of thinking and acting, enabling AI models to not only reason and "show their work" but also to proactively gather external information. This mirrors human problem-solving closely, enhancing AI's accuracy, trustworthiness, and performance on complex tasks. ReACT prompting embodies a shift towards AI that can interact with and understand the world in a manner akin to human cognition.

### Combining Thought and Action

ReAct prompting revolutionizes AI by enabling models to not only generate reasoning traces - essentially showing their work - but also to take actions, such as fetching information from external sources. This approach mirrors human problem-solving, where we think through a plan and then act on it, allowing the AI to dynamically adjust its strategy based on new information.

### Enhanced Accuracy and Trust

By interfacing with the external world, ReAct-equipped AIs can supplement their internal knowledge with up-to-date information, leading to more accurate and reliable responses. This ability to "think out loud" and show the reasoning process behind their conclusions also makes these AI models more transparent and trustworthy to users.

### Superior Performance on Complex Tasks

Through practical applications and research, ReAct has demonstrated its superiority over traditional methods in various complex tasks. Whether it's answering multifaceted questions, verifying facts, or navigating decision-making scenarios, ReAct's integration of reasoning and action enables AI to perform at a higher level, making significant strides toward AI that can understand and interact with the world more like humans do.

## Introducing CrewAI

At the heart of today's technological advancement, [CrewAI](https://www.crewai.io/). emerges as a multi-agent framework designed to revolutionize how engineers and developers leverage AI.

By prioritising collaborative intelligence, CrewAI enables multiple AI agents to work together, solving complex problems with enhanced creativity and decision-making. It's built on the principle of simplicity through modularity, allowing for customizable agent roles, goals, and tools.

> Crew AI is not just about automating tasks but fostering an environment where AI agents act as cohesive teams, demonstrating the potential for AI to work alongside humans in innovative ways

![[CrewAI](https://github.com/joaomdmoura/CrewAI?tab=readme-ov-file#key-features)](https://miro.medium.com/0*1J7ZvOpLeOiEZzN3.png)

## Let's assemble our AI Crew!

As we gear up to unveil the capabilities of CrewAI, my goal is crystal clear: to harness the power of AI to revolutionize the way we approach tasks, particularly in the realm of charity organizations. CrewAI, with its advanced AI agents, is not just about completing tasks; it's about redefining efficiency and innovation.

By delegating research and content creation to these AI agents, I aim to uncover new generative AI use cases that can significantly enhance the value charities provide to their communities.

> This endeavour is not merely about task automation; it's a mission to empower organizations to do more, with less, propelling them towards greater impact and service.

There are four steps in this process, first we install and import libraries, we then need to assemble our AI Crew and finally we kick off the workflow.

### 1. Install and Import Libraries and Setup our Tools

We will start by install and import our libraries from Crewai and Langchain.

We then set our search tool, we will use a free search tool from duckduckgo.

Finally, we will set up our chat language model. I am using Cohere's chat model availabe through langchain.

**Cohere** is a leading AI company specializing in natural language understanding and generation. By offering a powerful chat model, Cohere enables developers to build applications that can understand and generate human-like text. This capability is particularly useful for creating chatbots, automating customer service, and enhancing data analysis.

I chose Cohere's model for its advanced language understanding capabilities and ease of integration via LangChain. Their model's ability to grasp context and generate coherent responses aligns with my goal of developing AI-driven solutions that augment human work, especially in streamlining and innovating processes within charity organizations.

Get your free developer API key here: [Cohere | The leading AI platform for enterprise](https://cohere.com/)

```python
pip install --quiet crewai duckduckgo-search cohere serpapi beautifulsoup4
```

```python
import os
from crewai import Agent, Task, Crew, Process
from langchain_community.chat_models import ChatCohere
from langchain.tools import DuckDuckGoSearchRun
from langchain.agents import load_tools

search_tool = DuckDuckGoSearchRun() #enabling the agents to have access to the internet

os.environ["COHERE_API_KEY"] = "COHERE_API_KEY"
# Initiate our LLM chat model from Cohere
llm=ChatCohere(temperature=0.3)
```

### 2. Specifying AI Agent's Role, Goals, Backstories, Tasks and Tools

Here comes the fun part, we can now build our team, we can give them a role, a goal, a backstory and a task to complete. We can even give them access to tools to complete actions and maintain knowledge about the current state of the world.

Let's meet the team!

### Agent 1: Our Senior Research Analyst

This crew member's main purpose and goal is to research our real-world use cases, by enabling this agent to focus solely on this task, we can add complexity and a specific skill to complete our research. Once they have achieved the goal, their work will be passed on to the next agent, who we will meet shortly.

![ChatGPT Vision](https://miro.medium.com/0*UkTc8r-kUCUQcvDb)

**Role:** Senior Research Analyst',

**Goal:** Uncover real use cases of generative AI applied across charity organisations., search the internet to identifying real-life use cases',

**Backstory:** You are a Senior Research Analyst at a leading tech think tank.

Your expertise lies in identifying emerging trends and technologies in generative ai, identifying real-world use cases and providing the organisation name (you must know the actual company name), how they have applied it and the benefits they are experiencing.

You have a knack for dissecting complex data and presenting actionable insights.

**Task:** Conduct a comprehensive analysis of the latest use cases of generative AI applied across charity organisations. Search the internet to identifying real-life use cases'

Identifying real-world use cases and providing the organisation name(you must know the actual company name), how they have applied it and the benefits they are experiencing. Compile your findings in a detailed report.

Your final answer MUST be a full analysis report containing the full details of the generative ai use cases.

**Tools:** DuckDuckGoSearch (internet search)

```python
# Define your agents with roles and goals
researcher = Agent(
  role='Senior Research Analyst',
  goal='Uncover real use cases of generative AI...',
  backstory="""You are a Senior Research Analyst..."""
  verbose=True,
  allow_delegation=False,
  llm=llm,
  tools=[search_tool]
)

task1 = Task(
  description="""Conduct a comprehensive analysis of..""",
  agent=researcher
)
```

### Agent 2

This crew member's main purpose and goal is to take the research from our analyst and focus on their main skill which is to write compelling content, enabling our research to come to life.

![](https://miro.medium.com/0*uhIB6k0ONMzaU1Hr)

**Role:** Tech Content Strategist

**Goal:** Craft compelling content on tech advancements

**Backstory:** You are a renowned Tech Content Strategist, known for your insightful and engaging articles on technology and innovation. With a deep understanding of the tech industry, you transform complex concepts into compelling narratives.

**Task:** Using the insights from the researcher's report, develop an engaging blog post that highlights the most significant AI advancements. , search the internet to validate the real-life use cases.

Report on real-world use cases and provide the organisation name, how they have applied it and the benefits they are experiencing. Your post should be informative yet accessible, catering to a tech-savvy audience.

Aim for a narrative that captures the essence of these breakthroughs and their implications for the future.

 Your final answer MUST be the full blog post of at least 5 paragraphs.

**Tools:** DuckDuckGoSearch (internet search)

```python
writer = Agent(
  role='Tech Content Strategist',
  goal='Craft compelling content on tech advancements',
  backstory="""You are a renowned Tech Content Strategist...""",
  verbose=True,
  allow_delegation=False,
  llm=llm,
  # Passing search and human tools to the agent
  tools=[search_tool]
)

task2 = Task(
  description="""Using the insights from the researcher's report...""",
  agent=writer
)
```

### 3. Instantiate the Team and Kickoff the Workflow

Let's get the team to work, we just need to instantiate the crew and kickoff!

```bash
# Instantiate your crew with a sequential process
crew = Crew(
  agents=[researcher, writer],
  tasks=[task1, task2],
  verbose=1
)

# Get your crew to work!
result = crew.kickoff()

print("######################")
print(result)
```

## Final Research and Content

Our team completed their task in less than a minute! I was able to follow their thoughts, actions and observations through the verbose. Check this out below!

---

**Working Agent**: Senior Research Analyst

**Thought**: Do I need to use a tool?

**Yes Action**: duckduckgo_search

**Action Input**: "generative AI charity use cases"

**Final Answer_:_** "The results indicate several promising applications of generative AI in charities. Here are some notable examples:

1. **Red Cross:** The British Red Cross has utilized generative AI to create personalized disaster preparedness guides. Using AI-powered algorithms, the organization can now tailor emergency plans based on location, climate, and specific vulnerabilities. This ensures better preparation and improves the organization's response to crises.

2. **Charity: Water:** This organization has partnered with AI creative studio Persado to leverage generative AI for its #ReimagineWater campaign. AI-powered tools were used to create attention-grabbing visuals and marketing materials, enhancing their ability to communicate important messages and raise funds for clean water projects.

3. **UNESCO:** The United Nations Educational, Scientific and Cultural Organization has integrated generative AI into its ongoing initiatives. AI is used to translate and disseminate critical information and educational materials in multiple languages, making them accessible to a broader audience and facilitating cultural understanding.

These examples illustrate how generative AI is being applied in the charity sector, promoting efficiency, customization, and enhanced communication and advocacy."

**> Finished chain.**

---

**Working Agent:** Tech Content Strategist

**Thought:** Do I need to use a tool?

**Yes Action:** duckduckgo_search

**Action Input:** AI advancements in charities

**Observation:** A multitude of sources detailing charities adoption of AI technology to improve outreach, engagement, and fundraising.

**Thought:** Do I need to use a tool? No

**Final Answer:** Building on the draft written, here is an expanded version of the blog post highlighting the use of AI in charities

"In a world where technology constantly evolves and progresses, charities are embracing the latest advancements in AI to enhance their operations and maximize their impact on the world. From personalized disaster preparedness to AI-generated marketing materials and multilingual translation, these organizations demonstrate how AI promotes efficiency, customization, and enhanced communication in the charity sector.

The blog post will focus on three distinct charities: the Red Cross, Charity: Water, and UNESCO. These organizations harness the power of generative AI to pioneer innovative solutions and services to society's most pressing problems, truly demonstrating the potential of AI for good.

**The Red Cross** utilizes AI algorithms to create personalized disaster preparedness guides. These guides are tailored to individuals' locations, climates, and vulnerabilities, allowing the organization to respond more effectively to crises. By leveraging AI's predictive capabilities, the Red Cross can empower communities with vital information and increase their resilience in the face of potential disasters.

**Charity: Water**, an organization on a mission to provide clean drinking water worldwide partnered with AI creative studio Persado. Together they created attention-grabbing visuals and marketing materials to raise awareness and funds for their cause. By harnessing the creative powers of generative AI, Charity: Water can effectively communicate their mission, engaging their supporters and fostering meaningful action.

**UNESCO** integrates generative AI across several initiatives, notably its translation and dissemination of critical information. With AI, they can swiftly and accurately translate educational materials and press releases into multiple languages. This breakthrough technology breaks down language barriers and fosters cultural understanding worldwide.

These examples merely scratch the surface of how AI is transforming the charity industry. These organizations are pioneers, leveraging cutting-edge technology to streamline operations, amplify voices, and generate positive change on a global scale. The implications of these advancements are limitless, and as technology continues to evolve, we can only imagine what the future holds.

While this blog post has explored only a few examples, the charity sector is continually embracing AI's potential. No doubt, there are other inspiring use cases and innovative applications. Stay tuned for further updates and sign up for notifications to be the first to know about the latest AI advancements in charities and the extraordinary impact they have on the world."

**> Finished chain.**

---

### Verifications:

- Charity Water: [charity-water-Persado-Case-Study-May-2019–1.pdf](https://www.persado.com/wp-content/uploads/charity-water-Persado-Case-Study-May-2019-1.pdf)

- Red Cross: [How AI can help protect us from disasters - ITU Hub](https://www.itu.int/hub/2022/03/ai-disaster-management-early-warning/)

- UNESCO: [New report and guidelines for indigenous data sovereignty in artificial intelligence developments | UNESCO](https://www.unesco.org/en/articles/new-report-and-guidelines-indigenous-data-sovereignty-artificial-intelligence-developments)

Our final output provides a great starting point for researching additional content and fine-tuning the output to be more like your writing style and message. I am now able to continue my research and share my findings with the charity community.

## **Conclusion**

As we conclude this narrative, it's evident that CrewAI and Cohere are not just tools but catalysts for a paradigm shift in technological empowerment.

The synergy between human creativity and AI's capabilities has set the stage for unparalleled innovation. My experience stands as a testament to the transformative power of generative AI, offering a glimpse into a future where AI collaboration is not just a possibility but a staple of creative and analytical endeavors.

The journey with CrewAI is more than automation; it's about envisioning and realizing the art of the possible in a world augmented by AI.

I would love to hear your thoughts on the use of CrewAI, comment below and let me know how they could automate your workflow.

Follow me on [LinkedIn](https://www.linkedin.com/in/elle-neal-78994617/) for more tutorials and Generative AI content.