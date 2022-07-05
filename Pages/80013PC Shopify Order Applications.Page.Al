page 80013 "PC Shopify Order Applications"
{
    PageType = List;
    UsageCategory = Lists;
    ApplicationArea = All;
    SourceTable = "PC Shopfiy Order Applications";
    Caption = 'Shopify Order Applications';
 
    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(ShopifyOrderID; rec."Shopify Order ID")
                {
                    ApplicationArea = Basic;
                }
                field(ShopifyType;rec."Shopify App Type")
                {
                    ApplicationArea = Basic;
                }
                field(ShopifyDiscAppDesc;rec."Shopify Disc App Description")
                {
                    ApplicationArea = Basic;
                }
                field(ShopifyDiscAppValue;rec."Shopify Disc App Value")
                {
                    ApplicationArea = Basic;
                }
                field(ShopifyAppIndex;rec."Shopify Disc App Index")
                {
                    ApplicationArea = Basic;
                }
            }
        }
    }
}