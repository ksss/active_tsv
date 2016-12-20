#! /usr/bin/env ruby

require 'active_tsv'
require 'tempfile'
require 'active_hash'
require 'csv'
require 'objspace'
require 'stringio'

module ActiveHashTsv
  class Base < ActiveFile::Base
    SEPARATER = "\t"
    extend ActiveFile::HashAndArrayFiles
    class << self
      def load_file
        raw_data
      end

      def extension
        "tsv"
      end

      private

      def load_path(path)
        data = []
        CSV.open(path, col_sep: self::SEPARATER) do |csv|
          column_names = csv.gets.map(&:to_sym)
          while line = csv.gets
            data << column_names.zip(line).to_h
          end
        end
        data
      end
    end
  end
end

def open_csv_with_temp_table(n)
  headers = [*'a'..'j']
  Tempfile.create(["", ".tsv"]) do |f|
    f.puts headers.join("\t")
    n.times do |i|
      f.puts [*1..(headers.length)].map{ |j| i * j }.join("\t")
    end
    f.close
    yield f.path
  end
end
io = StringIO.new
$stdout = io
def b
  GC.start
  before = ObjectSpace.memsize_of_all
  realtime = Benchmark.realtime {
    yield
  }
  GC.start
  mem = (ObjectSpace.memsize_of_all - before).to_f
  [realtime, mem]
end
puts "title\tActiveHash\tActiveTsv\ttActiveHash\ttActiveTsv"
ns = [100, 200, 300, 400, 500]
ns.each do |n|
  open_csv_with_temp_table(n) do |path|
    hr, hm = b {
      h = Class.new(ActiveHashTsv::Base) do
        set_root_path File.dirname(path)
        set_filename File.basename(path).sub(/\..*/, '')
      end
      h.all.each {}
    }
    tr, tm = b {
      t = Class.new(ActiveTsv::Base) do
        self.table_path = path
      end
      t.all.each {}
    }
    puts sprintf("%d\t%0.5f\t%0.5f\t%d\t%d", n, hr, tr, hm, tm)

    hr, hm = b {
      h = Class.new(ActiveHashTsv::Base) do
        set_root_path File.dirname(path)
        set_filename File.basename(path).sub(/\..*/, '')
      end
      h.where(a: '10').first
    }

    tr, tm = b {
      t = Class.new(ActiveTsv::Base) do
        self.table_path = path
      end
      t.where(a: '10').first
    }
    puts sprintf("%d\t%0.5f\t%0.5f\t%d\t%d", n, hr, tr, hm, tm)
  end
end
$stdout = STDOUT
io.rewind
puts io.gets
lines = io.each_line.to_a
2.times do |i|
  puts lines.values_at(i, i+2, i+4, i+6, i+8)
end
