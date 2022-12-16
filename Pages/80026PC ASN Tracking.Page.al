page 80026 "PC ASN Tracking"
{
    Caption = 'ASN Tracking Log';
    PageType = Worksheet;
    SourceTable = "PC ASN Tracking";
    InsertAllowed = false;
    ModifyAllowed = false;
       
    PromotedActionCategoriesML = ENU = 'Pet Culture',
                                 ENA = 'Pet Culture';

    layout
    {
        area(content)
        {
            Group(Filters)
            {
                field("PO Number Filter"; PONum)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnDrillDown()
                    var
                        Pg:Page "Purchase Order List";
                        PurchHdr:Record "Purchase Header";
                    begin
                        PurchHdr.reset;
                        PurchHdr.Setrange("Document Type",PurchHdr."Document Type"::Order);
                        PurchHdr.SetRange("Order Type",PurchHdr."Order Type"::Fulfilo);    
                        Clear(PONum);
                        Pg.SetTableView(PurchHdr);
                        Pg.LookupMode := true;
                        if pg.RunModal() = Action::LookupOK then
                        begin
                            Pg.GetRecord(PurchHdr);
                            Ponum := PurchHdr."No."
                        end;
                        Setfilters;
                    end;
                    trigger OnAssistEdit()
                    begin
                        Clear(PONum);
                        Setfilters();
                    end;
                }
            }           
            repeater(General)
            {
                field("ASN Creation Date/Time"; Rec."ASN Creation Date/Time")
                {
                    ApplicationArea = All;
                }
                field("PO No."; Rec."PO No.")
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    var
                        PG:PAGE "Purchase Order";
                        PH:Record "Purchase Header";
                    begin
                        if PH.Get(PH."Document Type"::Order,Rec."PO No.") then
                        begin
                            PG.SetRecord(PH);
                            Pg.Run();   
                        end
                        else
                            Message('PO Not found');
                    end;    
                }
                field("Total Qty"; Rec."Total Qty")
                {
                    ApplicationArea = All;
                }
                field("Total Weight"; Rec."Total Weight")
                {
                    ApplicationArea = All;
                }
                field("ASN No.";rec."ASN No.")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
    trigger OnOpenPage()
    var
        ASNTrck:record "PC ASN Tracking";
    begin
        ASNtrck.Reset();
        ASNTrck.Setfilter("ASN Creation Date/Time",'<=%1',CreateDateTime(CalcDate('-1M',Today),0T));
        If ASNTrck.FindSet() then ASNTrck.DeleteAll(False);
        Commit;
    end;    
    local procedure Setfilters()
    Begin
        Rec.reset;
        If PONum <> '' then rec.Setrange("PO No.",PONum);
        CurrPage.update(false);    
    End;
    var
        PONum:code[20];

}
