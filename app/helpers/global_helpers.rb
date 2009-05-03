module Merb
  module GlobalHelpers
    # helpers defined here available to all views.
    
    def number_to_human_size(number)
      return nil if number.nil?
      
      ((number.to_f / 1024**2 * 100).round.to_f / 100).to_s + " MB"
    end
    
    def button_to(label, url, options = {})
      form(:action => url, :method => (options[:method] || :post)) do
        button label
      end
    end
        
  end
end
