class TaxTableFactory
    include Google4R::Checkout

    def effective_tax_tables_at(time)
        tax_table = TaxTable.new false
        tax_table.create_rule do |rule|
            rule.area = UsCountryArea.new(UsCountryArea::ALL)
            rule.rate = 0.0
        end
        [tax_table]
    end
end
