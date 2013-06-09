#  File name wlerror.rb
#  Copyright © by INRIA
# 
#  Contributors : Webdam Team <webdam.inria.fr>
#       Jules Testard <jules[dot]testard[@]mail[dot]mcgill[dot]ca>
#       Emilien Antoine <emilien[dot]antoine[@]inria[dot]fr>
# 
#   WebdamLog - 30 juin 2011
# 
#   Encoding - UTF-8
module WLBud

  # Raise when a method supposed to be override in subclass has not been defined
  class MethodNotImplementedError < StandardError; end

  #The standard error for our WebdamLog software
  class WLError < StandardError;
  end

  #The error thrown when a type is misused
  class WLErrorTyping < WLError
  end

  #Program parsing error
  class WLErrorGrammarParsing < WLError
  end

  #Error thrown when using a WLProgram object found in an inconsistent state
  class WLErrorProgram < WLError
  end

  #Error thrown when a peer cannot be identified
  class WLErrorPeerId < WLErrorProgram
  end

  #Error thrown when a callback method failed at invocation
  class WLErrorCallback < WLError
  end

  # Thrown by the wrapper WLRunner
  class WLErrorRunner < WLError
  end
  
end
