Factory.define :patron, :class => Barcode::Patron do |f|
  f.first_name    { 'Brice' }
  f.last_name     { 'Stacey' }
  f.barcode       { '0123456789' }
  f.patron_group  { 'STAFF' }
  f.email         { 'bricestacey@gmail.com' }
end
