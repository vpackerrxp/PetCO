page 80043 "PC Campaign SKU"
{
    ApplicationArea = All;
    Caption = 'Campaign SKU';
    PageType = List;
    SourceTable = "PC Campaign SKU";
    UsageCategory = Lists;
    
    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(Campaign; Rec.Campaign)
                {
                    ApplicationArea = All;
                }
                field(SKU; Rec.SKU)
                {
                    ApplicationArea = All;
                }
                field("Campaign Price"; Rec."Campaign Price")
                {
                    ApplicationArea = All;
                }
                field("Rebate Amount"; Rec."Rebate Amount")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
