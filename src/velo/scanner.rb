require 'velo/debug.rb'

debug "loading scanner"

class Scanner
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
    debug "set_token '#{@text}' (#{@type})"
    # debug "string now '#{@string}'"
  end

  def scan
    scan_impl
    debug "scanned '#{@text}' (#{@type})"
    return @text
  end

  def scan_impl
    m = /^\s+(.*)$/m.match @string
    @string = m[1] if not m.nil?

    if @string.empty?
      set_token('EOF', 'EOF')
      return
    end

    # check for any single character tokens
    m = /^([(),.;=])(.*)$/m.match @string
    if m
      @string = m[2]
      set_token(m[1], 'seperator')
      return
    end

    # check for strings of "word" characters
    m = /^(\w+)(.*)$/m.match @string
    if m
      @string = m[2]
      set_token(m[1], 'ident')
      return
    end

    # literal strings
    if @string[0] == ?{
      index = 1
      level = 1
      while level > 0
        if @string[index] == ?{
          level += 1
        elsif @string[index] == ?}
          level -= 1
        end
        index += 1
      end
      token = @string[1..index-2]
      @string = @string[index..@string.length-index]
      set_token(token, 'strlit')
      return
    end

    debug "scanner couldn't scan '#{@string}'"

    set_token('UNKNOWN', 'UNKNOWN')
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

if $0 == __FILE__
  $debug = true
  s = Scanner.new(ARGV[0])
  until s.text.nil?
    s.scan
  end
end
