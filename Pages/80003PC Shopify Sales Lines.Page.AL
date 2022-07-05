page 80003 "PC Shopify Sales Lines"
{
    PageType = List;
    SourceTable = "PC Shopify Order Lines";
    
    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(ShopifyOrderID; rec."Shopify Order ID")
                {
                    ApplicationArea = basic;
                }
                field(ShopifyOrderLineID; rec."Order Line ID")
                {
                    ApplicationArea = basic;
                }
                field(ShopifyOrderLineNo; rec."Order Line No")
                {
                    ApplicationArea = basic;
                }
                field(ItemNo; rec."Item No.")
                {
                    ApplicationArea = Basic;
                }
                field(OrderQty; rec."Order Qty")
                {
                    ApplicationArea = Basic;
                }
                field(UnitPrice;rec."Unit Price")
                {
                    ApplicationArea = Basic;
                }
                field(BaseAmount; rec."Base Amount")
                {
                    ApplicationArea = Basic;
                }
                field(TaxAmount; rec."Tax Amount")
                {
                    ApplicationArea = Basic;
                }
                field(DiscountAmount; rec."Discount Amount")
                {
                    ApplicationArea = Basic;
                }
                Field(AppsIndex;rec."Shopify Application Index")
                {
                    ApplicationArea = Basic;
                }
            }
        }
    }    
}
