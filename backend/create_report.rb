require 'json'
require './gemini'
require './search-web'

api_key = File.read(File.join(Dir.home, '.secret', 'gemini.txt')).strip

r = SearchWeb.new.search

client = Gemini::Gemini.new(
  credentials: {
    service: 'generative-language-api',
    api_key: api_key
  },
  options: { model: 'gemini-2.0-flash-exp', server_sent_events: true, system_instruction: <<~INSTRUCTION
    **Please create a report in Japanese using Markdown format, following the steps and policies outlined below. Use only the information provided by the user as the sole source (grounding), and avoid careless speculation or supplementation that could lead to hallucinations.**

    1. **Use only the information given by the user.** If additional information is needed or there are unclear points in the provided data, do not resort to speculation or external sources.  
    2. **Extract key information from the search results for each theme and summarize it concisely.**  
    3. **Integrate the summaries of each theme to create a coherent report.**  
    4. **Structure of the report**  
    - First, introduce the basic concepts of Docker.  
    - Next, introduce the basic concepts of Podman.  
    - Then, detail the main differences between Docker and Podman in terms of architecture, usage, security, etc.  
    - Finally, discuss their compatibility and migration.  

    **Please adhere strictly to these rules when creating the report.**
 INSTRUCTION
  }
)
r = client.generate_content({
    contents: [{ role: 'user', parts: [{ text: r }] }]
})
puts "============= Report"
puts r[:response]["content"]["parts"][0]["text"]