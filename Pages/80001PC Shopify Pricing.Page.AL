page 80001 "PC Shopify Pricing"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "PC Shopfiy Pricing";
    RefreshOnActivate = True;
    DelayedInsert = true;
    Caption = 'Shopify Price Management';        
    layout
    {
        area(Content)
        {
            group(Hdr)
            {
                ShowCaption = false;
                Visible = RefItem <> '';
                field("Item No"; rec."Item No.")
                {
                    ApplicationArea = All;
                    Style = Strong;
                    Editable = false;
                }
                field(Decription; desc)
                {
                    ApplicationArea = All;
                    Editable = false;
                    Style = Strong;
                }

                field(Price; RRP)
                {
                    Caption = 'Current RR Price';
                    ApplicationArea = All;
                    Editable = false;
                    Style = Strong;
                }
            }
            repeater(GroupName)
            {
                field("Item No."; rec."Item No.")
                {
                    ApplicationArea = All;
                    Visible = RefItem = '';
                }
                field(Description; rec.Description)
                {
                    ApplicationArea = All;
                }
                field("RR Price"; rec."RRP Price")
                {
                    ApplicationArea = All;
                    Caption = 'Current RRP Price';
                }
                field("New RRP Price";rec."New RRP Price")
                {
                    ApplicationArea = All;
                    Caption = 'New RRP Price';
                }
                field("Sell Price";rec."Sell Price")
                {
                    ApplicationArea = All;
                }
                field("Platinum Member Disc %";rec."Platinum Member Disc %")
                {
                    ApplicationArea = All;
                }
                field("Platinum + Auto Disc %";rec."Platinum + Auto Disc %")
                {
                    ApplicationArea = All;
                }
                field("Gold Member Disc %";rec."Gold Member Disc %")
                {
                    ApplicationArea = All;
                }
                field("Gold + Auto Disc %";rec."Gold + Auto Disc %")
                {
                    ApplicationArea = All;
                }
                field("Silver Member Disc %";rec."Silver Member Disc %")
                {
                    ApplicationArea = All;
                }
                field("Auto Order Disc %";rec."Auto Order Disc %")
                {
                    ApplicationArea = All;
                }
                field("VIP Disc %";rec."VIP Disc %")
                {
                    ApplicationArea = All;
                }
                field("Starting Date";rec."Starting Date")
                {
                    ApplicationArea = All;
                }
                field("Ending Date";rec."Ending Date")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            Action("CleanUp")
            {
                ApplicationArea = All;
                Caption = 'Clean Up Sales Data';
                Image = Change;
                Promoted = true;
                PromotedIsBig = true;
                trigger OnAction()
                var
                    cu:Codeunit "PC Shopify Routines";
                begin
                     If Confirm('Perform Cleanup of Sales Data Now',true) Then
                        Cu.Correct_Sales_Prices(RefItem);
                end;
            }
        }
    }            
    trigger OnOpenPage()
    begin
        if RefItem <> '' then rec.Setrange("Item No.",RefItem);
    end;
     procedure Set_item(ItemSrc:Code[20])
     var
        Item:Record Item;
     begin
         Clear(RefItem);
        If ItemSrc <> '' then
        begin
            RefItem := ItemSrc;
            Item.Get(RefItem);
            RRP := Item."Unit Price";
            Desc := Item.Description;
        end;    
     end;
     var
        RefItem:Code[20];
        RRp:Decimal;
        Desc:text;
        Closedate:array[2] of date;
}