# encoding: UTF-8

require_relative '../columns/attribute'

module GoodData
  module Model
    ##
    # Date field that's not connected to a date dimension
    #
    class DateAttribute < Attribute
      def key;
        "#{DATE_COLUMN_PREFIX}#{super}";
      end

      def to_manifest_part(mode)
        {
          'populates' => ['label.stuff.mmddyy'],
          'format' => 'unknown',
          'mode' => mode,
          'referenceKey' => 1
        }
      end
    end
  end
end
