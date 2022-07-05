page 80002 "PC Shopify Sales Header"
{
    PageType = List;
    SourceTable = "PC Shopify Order Header";
    
    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(ShopifyOrderID; rec."Shopify Order ID")
                {
                    ApplicationArea = Basic;
                }
                field(OrderDate; rec."Shopify Order Date")
                {
                   ApplicationArea = Basic;
                }
                field(ShopifyOrderNo; rec."Shopify Order No.")
                {
                    ApplicationArea = Basic;
                }
                field(OrderCurrency; rec."Shopify Order Currency")
                {
                   ApplicationArea = Basic;
                }
                field(OrderType; rec."Order Type")
                {
                   ApplicationArea = Basic;
                }
                field(CreditCardTotal; rec."Credit Card Total")
                {
                   ApplicationArea = Basic;
                }
                field(StoreCreditTotal; rec."Store Credit Total")
                {
                   ApplicationArea = Basic;
                }
                field(GiftCardTotal; rec."Gift Card Total")
                {
                   ApplicationArea = Basic;
                }
                field(FreightTotal; rec."Freight Total")
                {
                   ApplicationArea = Basic;
                }
                field(DiscountTotal; rec."Discount Total")
                {
                    ApplicationArea = Basic;
                }
            }
        }
    }
 }
 
