require 'bibtex'

class BibtexConverter
  
  class << self
    def process(input_hash)
      input_hash = input_hash.inject({}){|builder,(k,v)| builder[k.to_sym] = v ; builder}
      input_hash[:author] = convert_names(input_hash[:authors])
      input_hash[:editor] = convert_names(input_hash[:editors])
      input_hash[:type] = convert_type(input_hash[:type])
      [ :dateAccessed, :deletionPending, :isRead, :isStarred, :isAuthor, :authors, :editors].each { |key| input_hash.delete(key)} 
      bib = BibTeX::Entry.new(input_hash)
     ( bib.publisher = bib.publication_outlet.value ) if ( bib.publisher or bib.type == :inproceedings) && bib.respond_to?(:publication_outlet)
      bib.booktitle = bib.publication_outlet.value if ( bib.booktitle.nil?  && bib.respond_to?(:publication_outlet) )
      ( bib.publication_outlet, bib.published_in = nil, nil) if ( bib.booktitle or bib.publisher ) #ACCKKK! 
      bib.each { |k,v| bib.delete(k) if v.blank? }
      bib
    end
  
    def convert_type(type)
      types = { "Journal Article" => "article", "Conference Proceedings"  => "inproceedings"}
      types[type] ? types[type] : "article"
    end
  
    # [{"forename"=>"HT", "surname"=>"Abdelwahab"}]
    def convert_names(value)
      value.collect { |key| "#{key['surname']}, #{key['forename']}" }.join(" and ") 
    end
  end
    
  
end