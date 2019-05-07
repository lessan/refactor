require 'fileutils'

module Migrator
  def self.run
    virtus_json_enum_include_regex = /require 'virtus_another_enum\/jsonable_enum'\n/
    virtus_enum_attr_include_regex = /require 'virtus_another_enum\/attribute'\n/
    virtus_include_regex = /require 'virtus'\n/
    newlines_at_start_regex = /\A[\n]+/

    value_block_regex = /values do\n(.+)end\n/m
    value_block_replace = '\1'

    virtus_value_obj_regex = /\n[ ]+include Virtus\.value_object\n/
    virtus_value_obj_replace = " < Model\n"

    virtus_model_regex = /\n[ ]+include Virtus\.model\n/
    virtus_model_replace = " < Model\n"

    enum_class_regex = /< VirtusAnotherEnum::JsonableEnum/
    enum_class_replace = '< JsonableEnum'

    string_regex = /(attribute :[a-z_]+), String/
    string_replace = '\1, ::Types::String.optional.meta(omittable: true)'

    string_default_regex = /(attribute :[a-z_]+), String, default: -> \(_,_\) { ([A-Za-z:\.]+) }/
    string_default_replace = '\1, ::Types::String.optional.default(\2.freeze).meta(omittable: true)'

    bigdecimal_default_regex = /(attribute :[a-z_]+), BigDecimal, default: ([0-9a-zA-z]+)/
    bigdecimal_default_replace = '\1, ::Types::Decimal.optional.default(\2.freeze).meta(omittable: true)'

    time_regex = /(attribute :[a-z_]+), Time/
    time_replace = '\1, ::Types::Time.optional.meta(omittable: true)'

    date_regex = /(attribute :[a-z_]+), Date/
    date_replace = '\1, ::Types::JSON::Date.optional.meta(omittable: true)'

    integer_regex = /(attribute :[a-z_]+), Integer/
    integer_replace = '\1, ::Types::Integer.optional.meta(omittable: true)'

    boolean_default_regex = /(attribute :[a-z_]+), Boolean, default: ([a-z]+)/
    boolean_default_replace = '\1, ::Types::Bool.optional.default(\2.freeze).meta(omittable: true)'

    boolean_regex = /(attribute :[a-z_]+), Boolean/
    boolean_replace = '\1, ::Types::Bool.optional.meta(omittable: true)'

    hash_regex = /(attribute :[a-z_]+), Hash/
    hash_replace = '\1, ::Types::Hash.optional.meta(omittable: true)'

    string_array_regex = /\[String\]/
    string_array_replace = '[::Types::String]'

    array_default_regex = /Array\[(.+)\], default: \[\]/
    array_default_replace = '::Types::Array.of(\1).default([].freeze).meta(omittable: true)'

    array_regex = /Array\[(.+)\]/
    array_replace = '::Types::Array.of(\1).default([].freeze).meta(omittable: true)'

    enum_type_default_regex = /VirtusAnotherEnum::Attribute\[([A-Za-z:]+)\], default: ->\(_,_\) { ([A-Za-z:\.]+) }/
    enum_type_default_replace = '::Types::Constructor(\1){ |i| \1[i] }.default(\2.freeze).meta(omittable: true)'

    enum_type_required_regex = /VirtusAnotherEnum::Attribute\[([A-Za-z:]+)\], presence: true/
    enum_type_required_replace = '::Types::Constructor(\1){ |i| \1[i] }'

    enum_type_regex = /VirtusAnotherEnum::Attribute\[([A-Za-z:]+)\]/
    enum_type_replace = '::Types::Constructor(\1){ |i| \1[i] }.meta(omittable: true)'

    default_nil_regex = /, default: nil/
    default_nil_replace = ''

    custom_model_regex = /(attribute :[a-z_]+), ([A-Za-z:]+)\n/
    custom_model_replace = "\\1, \\2.optional.meta(omittable: true)\n"

    moolah_regex = /(attribute :[a-z_]+), Moolah::Money\.optional\.meta\(omittable: true\)/
    moolah_replace = "\\1, ::Types::Constructor(Moolah::Money).meta(omittable: true)"

    securerandom_regex = /\(SecureRandom\.uuid\.freeze\)/
    securerandom_replace = '{ SecureRandom.uuid }'

    # all files in current directory
    paths = Dir.glob('**/*')

    paths.each do |path|

      if File.file?(path)
        # replace within file
        old_text = File.read(path)
        # http://robots.thoughtbot.com/fight-back-utf-8-invalid-byte-sequences
        old_text.encode!('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')

        new_text = old_text.dup

        new_text.gsub!(virtus_json_enum_include_regex, '')
        new_text.gsub!(virtus_enum_attr_include_regex, '')
        new_text.gsub!(virtus_include_regex, '')
        new_text.gsub!(newlines_at_start_regex, '')

        new_text.gsub!(virtus_value_obj_regex, virtus_value_obj_replace)
        new_text.gsub!(virtus_model_regex, virtus_model_replace)
        new_text.gsub!(enum_class_regex, enum_class_replace)
        new_text.gsub!(enum_type_default_regex, enum_type_default_replace)
        new_text.gsub!(enum_type_required_regex, enum_type_required_replace)
        new_text.gsub!(enum_type_regex, enum_type_replace)
        new_text.gsub!(value_block_regex, value_block_replace)

        new_text.gsub!(string_default_regex, string_default_replace)
        new_text.gsub!(string_regex, string_replace)
        new_text.gsub!(bigdecimal_default_regex, bigdecimal_default_replace)
        new_text.gsub!(time_regex, time_replace)
        new_text.gsub!(date_regex, date_replace)
        new_text.gsub!(integer_regex, integer_replace)
        new_text.gsub!(boolean_default_regex, boolean_default_replace)
        new_text.gsub!(boolean_regex, boolean_replace)
        new_text.gsub!(hash_regex, hash_replace)
        new_text.gsub!(string_array_regex, string_array_replace)
        new_text.gsub!(array_default_regex, array_default_replace)
        new_text.gsub!(array_regex, array_replace)
        new_text.gsub!(default_nil_regex, default_nil_replace)

        new_text.gsub!(custom_model_regex, custom_model_replace)

        new_text.gsub!(moolah_regex, moolah_replace)
        new_text.gsub!(securerandom_regex, securerandom_replace)

        unless new_text == old_text
          # rewrite existing file
          File.write(path, new_text)
        end
      end
    end
  end
end
