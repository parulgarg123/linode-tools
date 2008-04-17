#!/usr/bin/ruby

require 'rexml/document'
require 'open-uri'

class LinodeInfo
  attr_reader :user, :user_agent, :xml

  @@base_url  = "http://www.linode.com/members/info/"
  @@date_fmt = "%Y-%m-%d %H:%M"
  @@max_age = 12 * 3600  # 12 hours

  def initialize(user)
    @state = ENV["HOME"] + "/.bw_state"
    @user = user
    @user_agent = "BandWidth Snarf v1.11/#{user}"
  end

  def method_missing(sym)
    key = sym.id2name
    fetch if not @data

    if ["xml","document","source","data"].include?(sym)
      send(sym)
    elsif @data.has_key?(key)
      @data[key]
    else
      raise NoMethodError, "undefined method `#{key}' for #{self}"
    end
  end

  def fetch(force=false)
    if force
      # try to read server
      begin
        _read_server
      # fall back to statefile
      rescue
        _read_statefile
      end
    elsif File.exist?(@state) and (Time.now - File.mtime(@state)) < @@max_age
      _read_statefile
    else
      _read_server
    end
    @document = REXML::Document.new(@xml).elements["linData"]
    _parse
    self
  end

  def summary
    kib = 1024
    mib = kib * 1024
    gib = mib * 1024

    s = self
    str = ""
    if (s.rx + s.tx) != s.total_xfer
      str += "Hmmm. My tx+rx count != caker's total_bytes count!"
      str += "Additionally, you shouldn't ever see this message."
    end

    str += sprintf("%s: (from %s; %s)\n",
      s.hostname, @source, s.timestamp.strftime(@@date_fmt))
    str += sprintf("    currently %s with %d jobs pending\n",
      s.hostload, s.jobs)
    str += sprintf("    up since: %s; avg cpu: %02.3f\n",
      s.upsince.strftime(@@date_fmt), s.cpu)
    str += sprintf("    net usage: %02.2f%% of %02.2f GiB\n",
      (s.total_xfer / s.max_xfer) * 100, s.max_xfer/gib)
    str += sprintf("    xfer: %02.2f GiB IN + %02.2f GiB OUT = %02.2f GiB TOTAL\n",
      s.rx/gib, s.tx/gib, s.total_xfer/gib)
    str
  end

  def _parse
    d = @document
    @data = {
      "max_xfer" =>   d.elements["bwdata/max_avail/text()"].to_s.to_i,
      "total_xfer" => d.elements["bwdata/total_bytes/text()"].to_s.to_f,
      "rx" =>         d.elements["bwdata/rx_bytes/text()"].to_s.to_f,
      "tx" =>         d.elements["bwdata/tx_bytes/text()"].to_s.to_f,
      "hostname" =>   d.elements["host/host/text()"],
      "hostload" =>   d.elements["host/hostLoad/text()"].to_s.upcase,
      "jobs" =>       d.elements["host/pendingJobs/text()"].to_s.to_i,
      "upsince" =>    Time.parse(d.elements["upSince/text()"].to_s),
      "cpu" =>        d.elements["cpuConsumption/text()"].to_s.to_f,
      "timestamp" =>  Time.parse(d.elements["request/DateTimeStamp/text()"].to_s),
    }
  end

  def _read_server
    conn = URI.parse("#{@@base_url}?user=#{@user}")
    xml = conn.read("User-Agent" => @user_agent)
    if xml.include?("<error>")
      err = REXML::Document.new(xml).elements["//error/text()"]
      raise IOError, "invalid data returned by server: #{err}"
    else
      # write fresh data to statefile.
      open(@state,'w') {|f| f.write(xml)}
    end
    @source = "server"
    @xml = xml
  end

  def _read_statefile
    @xml = IO.read(@state)
    @source = "file"
  end
end

if $0 == __FILE__
  if ARGV[0]
    user = ARGV[0]
  else
    user = ENV["USER"]
  end
  info = LinodeInfo.new(user)
  puts info.summary
end

