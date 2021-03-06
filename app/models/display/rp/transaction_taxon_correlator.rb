module Display
  module Rp
    class TransactionTaxonCorrelator
      Transaction = Struct.new(:name, :taxon, :homepage, :loa_list)
      Taxon = Struct.new(:name, :transactions)

      def initialize(rp_display_repository, rps_with_homepage_link, rps_with_name_only)
        @rp_display_repository = rp_display_repository
        @rps_with_homepage_link = rps_with_homepage_link
        @rps_with_name_only = rps_with_name_only
      end

      def correlate(data)
        data = filter_for_allowed_transactions(data)
        transaction_list = map_to_transactions(data)
        transaction_list = sort_transactions(transaction_list)
        taxon_groups = group_by_taxon(transaction_list)
        taxons = sort_taxons(taxon_groups)
        return taxons
      rescue KeyError => e
        Rails.logger.error e
        []
      end

    private

      def map_to_transactions(data)
        data.map do |item|
          display_data = @rp_display_repository.get_translations(item.fetch('simpleId'))
          homepage = @rps_with_name_only.include?(item.fetch('simpleId')) ? nil : item.fetch('serviceHomepage', nil)
          # if there's no homepage, move the transaction down to the 'Other service' taxon
          taxon = homepage.nil? ? other_services_translation : display_data.taxon
          loa_list = item.fetch('loaList')
          Transaction.new(display_data.name, taxon, homepage, loa_list)
        end
      end

      def filter_for_allowed_transactions(data)
        all_allowed_rps = @rps_with_homepage_link + @rps_with_name_only
        data.keep_if { |transaction| all_allowed_rps.include? transaction.fetch('simpleId') }
      end

      def sort_transactions(transactions)
        # Prioritise transactions with a homepage, and then sort alphabetically.
        transactions.sort do |x, y|
          if x.homepage.nil? && !y.homepage.nil?
            1
          elsif !x.homepage.nil? && y.homepage.nil?
            -1
          else
            x.name.casecmp(y.name)
          end
        end
      end

      def sort_taxons(taxons)
        # Sort alphabetically, except putting 'Other services' at the bottom of the list.
        taxons.sort do |x, y|
          if x.name == other_services_translation
            1
          elsif y.name == other_services_translation
            -1
          else
            x.name.casecmp(y.name)
          end
        end
      end

      def other_services_translation
        I18n.translate('hub.transaction_list.other_services')
      end

      def group_by_taxon(transactions)
        transactions
            .group_by { |transaction| transaction[:taxon] }
            .map { |name, taxon_transactions| Taxon.new(name, taxon_transactions) }
      end
    end
  end
end
