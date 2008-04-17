#!/usr/bin/python

import os, time
import urllib, urllib2
from xml.dom import minidom
from xml.xpath import Evaluate


class Info(object):
  date_fmt = "%Y-%m-%d %H:%M:%S.00"
  max_age = 12 * 3600   # 12 hours
  base_url = "http://www.linode.com/members/info/"

  def __init__(self, user):
    self.state = os.environ["HOME"] + "/.bw_state"
    self.user = user
    self.user_agent = "BandWidth Snarf v1.11/%s" % user

  def __getattr__(self, name):
    if name in ["xml","document","source","_data"]:
      self.fetch()
      return getattr(self, name)

    if self._data.has_key(name):
      return self._data[name]
    raise AttributeError("no such field '%s'" % name)

  def __str__(self):
    KiB = 1024
    MiB = KiB * 1024
    GiB = MiB * 1024

    str = ""
    if self.rx + self.tx != self.total_xfer:
      str += """Hmmm. My tx+rx count != caker's total_bytes count!
      Additionally, you shouldn't ever see this message.\n"""
    str += "%s: (from %s; %s)\n" % (self.hostname, self.source, self.timestamp)
    str += "    currently %s with %d jobs pending\n" % (self.hostload, self.jobs)
    str += "    up since: %s; avg cpu: %02.3f\n" % (self.upsince, self.cpu)
    str += "    net usage: %02.2f%% of %02.2f GiB\n" % \
        ((self.total_xfer/self.max_xfer * 100), self.max_xfer/GiB)
    str += "    xfer: %02.2f GiB IN + %02.2f GiB OUT = %02.2f GiB TOTAL\n" % \
        (self.rx/GiB, self.tx/GiB, self.total_xfer/GiB)
    return str

  def __repr__(self):
    return "%s('%s')" % (self.__class__.__name__, self.user)

  def fetch(self, force=False):
    try:
      state_age = time.time() - os.path.getmtime(self.state)
    except OSError:
      state_age = self.max_age
      force = True
    if force or state_age > self.max_age:
      self.source = "server"
      # fetch new data from server
      self.url = self.base_url + "?" + urllib.urlencode({"user":self.user})
      req = urllib2.Request(self.url)
      req.add_header("User-Agent",self.user_agent)
      self.xml = urllib2.urlopen(req).read().strip()
      # save newly fetched data to statefile
      f = open(self.state, "w")
      f.write(self.xml)
      f.close()
      self.document = minidom.parseString(self.xml).documentElement
    else:
      self.source = "file"
      self.xml = open(self.state).read().strip()
      self.document = minidom.parseString(self.xml).documentElement
    self._parse()
    return self

  def _parse(self):
    d = self.document
    self._data = {
      'max_xfer':   int(Evaluate('bwdata/max_avail/text()', d)[0].data),
      'rx':         float(Evaluate('bwdata/rx_bytes/text()', d)[0].data),
      'tx':         float(Evaluate('bwdata/tx_bytes/text()', d)[0].data),
      'total_xfer': float(Evaluate('bwdata/total_bytes/text()', d)[0].data),
      'hostname':   Evaluate('host/host/text()', d)[0].data,
      'hostload':   Evaluate('host/hostLoad/text()', d)[0].data.upper(),
      'jobs':       int(Evaluate('host/pendingJobs/text()', d)[0].data),
      'upsince':    Evaluate('upSince/text()', d)[0].data,
      'cpu':        float(Evaluate('cpuConsumption/text()', d)[0].data),
      'timestamp':  Evaluate('request/DateTimeStamp/text()', d)[0].data,
    }


if __name__ == "__main__":
  print Info("penryu")

