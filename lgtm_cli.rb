require 'RMagick'
require 'optparse'

class LGTMBuilder
  LGTM_IMAGE_WIDTH = 1_000

  def initialize(in_filepath)
    @sources = Magick::ImageList.new(in_filepath)
  end

  def build(out_filepath, options = {})
    images = Magick::ImageList.new

    @sources.each_with_index do |source, index|
      target = source
      target = blur(target) if options[:blur]
      target = lgtmify(target, options)
      target = glitch(target) if options[:glitch]
      target.delay = source.delay
      images << target
    end

    images.iterations = 0

    images.
      optimize_layers(Magick::OptimizeLayer).
      write(out_filepath)
  end

  private

  def width
    @sources.first.columns
  end

  def height
    @sources.first.rows
  end

  def lgtm_image(options)
    return @lgtm_image if @lgtm_image

    scale = width.to_f / LGTM_IMAGE_WIDTH
    if options[:with_comments]
      path = './images/lgtm_with_comments.gif'
    else
      path = './images/lgtm.gif'
    end
    @lgtm_image = ::Magick::ImageList.new(path).scale(scale)
  end

  def glitch(source)
    colors = []
    color_size = source.colors
    blob = source.to_blob
    color_size.times do |index|
      colors << blob[20 + index, 3]
    end
    color_size.times do |index|
      blob[20 + index, 3] = colors.sample
    end
    Magick::Image.from_blob(blob).first
  end

  def blur(source)
    source.blur_image(0.0, 5.0)
  end

  def lgtmify(source, options)
    source.composite!(
      lgtm_image(options),
      ::Magick::CenterGravity,
      ::Magick::OverCompositeOp
    )
  end
end



opts = ARGV.getopts('i:o:gbc')

LGTMBuilder.new(opts['i']).build(
    opts['o'],
    {
        :glitch => opts['g'],
        :blur => opts['b'],
        :with_comments => opts['c']
    }
)
