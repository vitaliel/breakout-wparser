module Breakout
  class WikiParser
   attr_accessor :last_mark

   def self.show_char(ch)
     print "'" << ch << "'"
   end

  %%{
    machine wiki_parser;
    write data;

    # -------------- Actions -------------
    action mark          { pr.new_ctx(p); }
    action mark_tmpl     { pr.new_tmpl_ctx(p); p += 1; }
    action old_ticket    { pr.ctx = :ticket; pr.p = p }
    action old_svn       { pr.ctx = :svn; pr.p = p }
    action old_git       { pr.ctx = :git; pr.p = p }

    action ticket_tmpl  { pr.ctx = :ticket_tmpl; pr.p = p }

    action done      { pr.finish; fbreak; }

    EOF = 0;
    start_br = '[[';
    end_br = ']]';

    ticket_re = ( "#" digit+ ) >mark %old_ticket;
    svn_re = space ("r" digit+ ) >mark %old_svn;
    git_re = ( "[" xdigit{7,} "]") >mark %old_git;

    # templates
    ticket_t = (start_br 'ticket:'i >mark digit+ end_br) %ticket_tmpl;

    text = ticket_t | ticket_re | svn_re | git_re;

    main := (text | any)* (EOF @done);
  }%%

  class Parser
    attr_accessor :ctx, :blocks, :data, :p, :start

    def initialize(data)
      @blocks = []
      self.data = data
      @last_p = 0
      @p = 0
      @start = 0
    end

    def new_tmpl_ctx(p)
      print "tmpl "
      new_ctx(p)
      self.start = p + 1
      @last_p = start
    end

    def new_ctx(p)
      finish
      puts "old ctx: #{ctx}, p:#{p}, ch:#{"" << data[p]}"
      puts " blocks:#{@blocks.inspect}"
      self.start = p
    end

    def add_chars(txt)
      if @blocks.size > 0 && @blocks.last[0] == :chars
        @blocks[@blocks.size-1] = [:chars, txt]
      else
        @blocks << [:chars, txt]
      end
    end

    def add_ticket_tmpl
      t = data[start+7..p-3]
      @blocks << [:ticket, t] if t.length > 0
    end

    def add_ticket
      return if start > p
      # puts(start, @p)
      @blocks << [ctx, data[start + 1..p-1]]
      # puts @blocks.last.inspect
    end

    def add_svn
      @blocks << [ctx, data[start + 1..p-1]]
    end

    def add_git
      @blocks << [ctx, data[start+1..p-2]]
    end

    def finish
      unless ctx.nil?
        st = start

        if ctx == :ticket_tmpl
          st -= 2
        end

        if @last_p < st
          add_chars(data[@last_p..st-1])
        end

        send("add_#{ctx}")
      else
        if @last_p > 0
          add_chars(data[@last_p..p-1])
        end
      end

      @last_p = p
    end
  end

  class << self
      def parse(txt)
        data = "\n" << txt << 0
        pr = Parser.new(data)

        %% write init;

        eof = pe

        %% write exec;

        p pr.blocks

        # Remove new line from beginning
        if pr.blocks[0][1].length > 1
          pr.blocks[0][1] = pr.blocks[0][1][1..-1]
        else
          pr.blocks.shift
        end

        pr.blocks
      end
    end
  end
end
