# encoding: UTF-8

module GoodData
  module Model
    class   MdObject
      attr_accessor :name, :title

      def visual
        "TITLE \"#{title_esc}\""
      end

      def title_esc
        title.gsub(/"/, "\\\"")
      end

      ##
      # Generates an identifier from the object name by transliterating
      # non-Latin character and then dropping non-alphanumerical characters.
      #
      def identifier
        @identifier ||= "#{self.type_prefix}.#{name}"
      end
    end
  end
end