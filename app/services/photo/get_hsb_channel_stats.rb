class Photo::GetHSBChannelStats
  def self.call(colour_data)
    # Ignore any colours that don't occupy at least 0.2% of the canvas.
    min_occurance = get_min_occurance(colour_data) 
    colour_data.select! { |c| c[:occurances] > min_occurance }

    {
      h: get_channel_stats(colour_data, :h),
      s: get_channel_stats(colour_data, :s),
      b: get_channel_stats(colour_data, :b)
    }
  end

  private

  def self.get_min_occurance(colour_data)
    colour_data.inject(0) { |result, elem| result += elem[:occurances] } / 500
  end

  def self.get_channel_stats(all_colours, channel)
    colours   = all_colours.map { |c| [c[:hsb][channel]] * (c[:occurances] / 500.0).ceil}.flatten
    mean      = Maths.mean(colours)
    deviation = Maths.standard_deviation(colours)
    outliers  = get_outliers(all_colours, colours, channel, mean, deviation)

    return {
      colours:   colours,
      mean:      mean,
      deviation: deviation,
      outliers:  outliers
    }

  end

  def self.get_outliers(all_colours, measuring_colours, channel, mean, deviation, threshold=1)
    outliers = []
    all_colours.each do |c| 

      z_score = Maths.z_score(c[:hsb][channel], measuring_colours, mean, deviation).abs
      if z_score > threshold

        # For saturation and brightness, we only want colors ABOVE the mean (positive z-score)
        if channel == :h || c[:hsb][channel] > mean
          c[:z_score] = z_score
          outliers.push(c)
        end
      end
    end
    outliers
  end

end