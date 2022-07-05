page 80022 "PC Fulfilo Inv Reasons"
{
    Caption = 'Fulfilio Inventory Reasons';
    PageType = List;
    UsageCategory = Lists;
    ApplicationArea = All;
    SourceTable = "PC Fulfilo Inv. Delta Reasons";
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Editable = false;
   
    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(SKU; rec.SKU)
                {
                    ApplicationArea = All;
                }
                field("Location Code"; rec."Location Code")
                {
                    ApplicationArea = All;
                }
                field("Adjusted DateTime"; rec."Adjusted DateTime")
                {
                    ApplicationArea = All;
                }
                field("Reason Code"; rec."Reason Code")
                {
                    ApplicationArea = All;
                }
                field("Reason Description"; Rec."Reason Description")
                {
                    ApplicationArea = All;
                }
                field("Sub Reason Code"; rec."Sub Reason Code")
                {
                    ApplicationArea = All;
                }
                field("Sub Reason Description"; Rec."Sub Reason Description")
                {
                    ApplicationArea = All;
                }
                field("Adjusted Qty"; rec."Adjusted Qty")
                {
                    ApplicationArea = All;
                }
                field("Adjusted In BC"; rec."Adjusted In BC")
                {
                    ApplicationArea = All;
                }
                field("BC Adjustment DateTime"; rec."BC Adjustment DateTime")
                {
                    ApplicationArea = All;
                }
            }
        }   
    }
}