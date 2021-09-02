module Rules
  class Sequence < Proc
    def call(*args)
      super(sequence.next, *args)
    end

    def sequence
      @sequence ||= 0.step(by: 1)
    end
  end
end
