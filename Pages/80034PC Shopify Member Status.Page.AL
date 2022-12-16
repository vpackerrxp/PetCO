page 80034 "PC Shopify Member Status"
{
    PageType = List;
    SourceTable = "PC Shopify Order Header";
    SourceTableView = Where("Shopify Order Member Status" = filter(''));
    Caption = 'Shopify Member Status';
    
    PromotedActionCategoriesML = ENU = 'Pet Culture',
                                 ENA = 'Pet Culture';

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(ShopifyOrdID;rec."Shopify Order ID")
                {
                    ApplicationArea = Basic;
                }
                field(ShopifyMemberStatus;rec."Shopify Order Member Status")
                {
                    ApplicationArea = Basic;
                }
            }
        }
    }
}            
