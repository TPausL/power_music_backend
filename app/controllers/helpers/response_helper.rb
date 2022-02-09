module Helpers::ResponseHelper
  def success(message, object = {})
    return(
      (
        Jbuilder.new do |r|
          r.message message
          r.object object
        end
      ).target!
    )
  end
  def error(message, errors = {})
    return(
      (
        Jbuilder.new do |r|
          r.message message
          r.errors errors
        end
      ).target!
    )
  end
end
