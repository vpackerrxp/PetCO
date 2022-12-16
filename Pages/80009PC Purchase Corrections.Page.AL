page 80009 "PC Purchase Corrections"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "PC Purchase Corrections";
    Caption = 'Fulfilio Purchase Corrections .. Fulfilio Status(Completed)';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;

    PromotedActionCategoriesML = ENU = 'Pet Culture',
                                 ENA = 'Pet Culture';

    layout
    {
        area(Content)
        {
            group(Ord)
            {
                ShowCaption = false;
                field("Purchase Order No.";rec."PO")
                {
                    ApplicationArea = All;
                    Caption = 'Purchase Order No.';
                }
                field("Correction Filter";Corr)
                {
                    ApplicationArea = All;
                    trigger OnValidate()
                    begin
                        rec.Reset;
                        rec.Setrange(User,UserId);
                        Case Corr Of     
                            Corr::Corrected: rec.Setrange("Correction Status",rec."Correction Status"::Corrected);
                            Corr::Unchanged: rec.Setrange("Correction Status",rec."Correction Status"::Unchanged);
                            Corr::"Not Ordered": rec.Setrange("Correction Status",rec."Correction Status"::"Not Ordered");
                            Corr::"Unknown SKU": rec.Setrange("Correction Status",rec."Correction Status"::"Unknown SKU");
                        end;   
                        currpage.Update(false);
                    end;    
                }
           }
            repeater(GroupName)
            {
                field(SKU; rec.Sku)
                {
                    ApplicationArea = All;
                }
                field(Description; rec.Description)
                {
                    ApplicationArea = All;
                }
                field("Original Order Qty"; rec."Original Order Qty")
                {
                    ApplicationArea = All;
                }
                field("Fulfilo Corrected Qty"; rec."Fulfilo Corrected Qty")
                {
                    ApplicationArea = All;
                    StyleExpr = Styler;
                }
                field("Correction Status"; rec."Correction Status")
                {
                    ApplicationArea = All;
                    StyleExpr = Styler;
                }
            }
            group("")
            {
               field("Display Count"; rec.Count)
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
            }
        }
    }
    trigger OnAfterGetRecord()
    begin
        if rec."Correction Status" = rec."Correction Status"::Unchanged then 
            Styler:= 'Favorable'
        else If rec."Correction Status" = rec."Correction Status"::Corrected then
            Styler := 'Unfavorable'
        else If rec."Correction Status" = rec."Correction Status"::"Not Ordered" then
            Styler := 'Strong'
       else If rec."Correction Status" = rec."Correction Status"::"Unknown SKU" then
            Styler := 'StrongAccent'
       else     
            Styler := 'None';
    end;
    var 
        Styler:text;
        Corr:Option All,Unchanged,Corrected,"Not Ordered","Unknown SKU";
}

