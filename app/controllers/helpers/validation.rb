module Helpers::Validation
  def validate(attribute, key)
    begin
      current_user.public_send(attribute).find(params[key])
    rescue => error
      render json:
               error(
                 "There is no #{attribute.to_s.singularize} with this #{key}!",
               )
    end
  end
end
