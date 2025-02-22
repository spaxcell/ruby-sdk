module ConfigCat

  class User
    #
    #    The user object for variation evaluation
    #

    PREDEFINED = ["Identifier", "Email", "Country"]

    def initialize(identifier, email: nil, country: nil, custom: nil)
      @__identifier = (!identifier.equal?(nil)) ? identifier : ""
      @__data = {"Identifier" => identifier, "Email" => email, "Country" => country}
      @__custom = custom
    end

    def get_identifier()
      return @__identifier
    end

    def get_attribute(attribute)
      attribute = attribute.to_s
      if PREDEFINED.include?(attribute)
        return @__data[attribute]
      end

      if !@__custom.equal?(nil)
        @__custom.each do |customField, customValue|
          if customField.to_s == attribute
            return customValue
          end
        end
      end
      return nil
    end

    def to_s()
      r = %Q({\n    "Identifier": "#{@__identifier}")
      if !@__data["Email"].equal?(nil)
        r += %Q(,\n    "Email": "#{@__data["Email"]}")
      end
      if !@__data["Country"].equal?(nil)
        r += %Q(,\n    "Country": "#{@__data["Country"]}")
      end
      if !@__custom.equal?(nil)
        r += %Q(,\n    "Custom": {)
        for customField in @__custom
          r += %Q(\n        "#{customField}": "#{@__custom[customField]}",)
        end
        r += "\n    }"
      end
      r += "\n}"
      return r
    end
  end

end
