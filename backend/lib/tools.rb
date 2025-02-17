require_relative 'gemini/decorator'
require_relative 'agents/deep_research'

module Tools
  Gemini::FunctionDecorator.doc(:find_movies,
    "find movie titles currently playing in theaters based on any description, genre, title words, etc.",{
    location: ["string","The city and state, e.g. San Francisco, CA or a zip code e.g. 95616"],
    description: ["string","required","Any kind of description including category or genre, title words, attributes, etc."]
  })
  def self.find_movies(location, description)
    return "find_movies called with location: #{location}, description: #{description}. The answer is StarGate."
  end

  Gemini::FunctionDecorator.doc(:deep_research,
    "Executes DeepResearch based on the user's request to generate strategy, search results, and a report.",
    {
      user_request: ["string", "required", "The user's research request."]
    }
  )
  def self.deep_research(user_request)
    return Agent::DeepResearcher.new.invoke(user_request)
  end

end
