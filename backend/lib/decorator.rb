module Gemini
  class FunctionDecorator
    @method_doc = {}

    def self.doc(func_name, description, params)
      @method_doc[func_name] = {
        description: description,
        params: params,
      }
      "h"
      p @method_doc[func_name]
    end

    def self.to_def(method_name)
      p @method_doc
      method_metadata = @method_doc[method_name]
      {
        "name": method_name.to_s,
        "description": method_metadata[:description],
        "parameters": {
          "type": "object",
          "properties": method_metadata[:params].transform_values do |param|
            {
              "type": param[0],
              "description": param[-1]
            }
          end,
          "required": method_metadata[:params].select { |_, v| v.include?("required") }.keys.map(&:to_s)
        }
      }
    end
  end
end