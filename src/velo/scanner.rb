puts "loading scanner"

class Tokenizer
  def initialize s
    @string = s
    @text = nil
    @type = nil
    scan_impl
  end

  def text
    return @text
  end

  def type
    return @type
  end

  def set_token(text, type)
    @text = text
    @type = type
  end

  def scan
    scan_impl
    return @text
  end

  def scan_impl
    m = /^\s+(.*?)$/.match @string
    @string = m[1] if not m.nil?

    if @string.empty?
      set_token(nil, nil)
      return
    end

    # check for any single character tokens
    m = /^([(),.;=])(.*?)$/.match @string
    if m
      @string = m[2]
      set_token(m[1], 'seperator')
      return
    end

    # check for strings of "word" characters
    m = /^(\w+)(.*?)$/.match @string
    if m
      @string = m[2]
      set_token(m[1], 'ident')
      return
    end

    # literal strings
    if @string[0] == '{'
      index = 1
      level = 1
      while level > 0
        if @string[index] == '{'
          level += 1
        elsif @string[index] == '}'
          level -= 1
        end
        index += 1
      end
      token = @string[1..index-2]
      @string = @string[index..@string.length-index]
      set_token(token, 'strlit')
      return
    end

    set_token(nil, nil)
  end

  def consume s
    if @text == s
      scan
      true
    else
      false
    end
  end

  def expect s
    if @text == s
      scan
    else
      raise VeloSyntaxError, "expected '#{s}', found '#{@text}'"
    end
  end
end
