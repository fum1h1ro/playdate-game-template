RESOURCE_SRC_DIR = 'resource'.freeze
RESOURCE_DST_DIR = 'Source/resource'.freeze
RESOURCE_SRCS = FileList['resource/**/*'].exclude do |f|
  File.directory?(f) || File.extname(f) == '.tsx'
end
RESOURCE_DSTS = RESOURCE_SRCS.map do |f|
  f
    .sub(/^#{RESOURCE_SRC_DIR}\//, "#{RESOURCE_DST_DIR}/")
    .sub(/\.mp3$/, '.wav')
    .sub(/\.tmx$/, '.til')
end

CLOBBER.include(RESOURCE_DST_DIR)

desc 'Convert resource files'
task conv: RESOURCE_DSTS

rule %r{^Source/.+\.wav$} => '%{^Source/,}X.mp3' do |t|
  mkdir_p File.dirname(t.name)
  sh "ffmpeg -i #{t.source} -acodec adpcm_ima_wav -ar 44100 #{t.name}"
end

rule %r{^Source/.+\.wav$} => '%{^Source/,}X.wav' do |t|
  mkdir_p File.dirname(t.name)
  sh "ffmpeg -i #{t.source} -acodec adpcm_ima_wav -ar 44100 -ac 1 #{t.name}"
end

rule %r{^Source/.+\.png$} => '%{^Source/,}X.png' do |t|
  mkdir_p File.dirname(t.name)
  cp t.source, t.name
end

rule %r{^Source/.+\.til$} => '%{^Source/,}X.tmx' do |t|
  mkdir_p File.dirname(t.name)
  sh "ruby Tool/tmxconv.rb #{t.source} -o #{t.name}"
end
