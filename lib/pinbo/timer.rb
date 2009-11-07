module Pinbo::Timer
  def timer(tags = {}, &block)
    Pinbo.timer(tags, &block)
  end
end