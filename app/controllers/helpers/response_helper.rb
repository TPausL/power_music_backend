module Helpers::ResponseHelper
  def success(message, object = {})
    return(
      (
        Jbuilder.new do |r|
          r.message message
          if object.is_a? Enumerable
            r.object do
              object.each do |o|
                r.child! do |n|
                  n.merge! defined?(o.to_builder) ? o.to_builder : o
                end
              end
            end
          else
            r.object defined?(object.to_builder) ? object.to_builder : object
          end
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
