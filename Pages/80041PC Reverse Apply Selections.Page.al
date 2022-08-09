page 80041 "PC Reverse Apply Selections"
{
    Caption = 'PC Reverse Apply Selections';
    PageType = List;
    SourceTable = Item;
    SourceTableTemporary = true;
    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Document No.";Rec."No.")
                {
                    ApplicationArea = All;
                    Style = Strong;
                }    
            }
        }
    }
    trigger OnOpenPage()
    var
        Recon:Record "PC Order Reconciliations";
        OrdHdr:record "PC Shopify Order Header";
        win:Dialog;
    Begin
        Win.Open('Building Document List .... please wait');
        Recon.reset;
        If ApplyType > 0 then
            Recon.setrange("Apply Status",ApplyType);
        Recon.SetFilter("Order Total",'>0');
        If Recon.Findset then
        repeat
            OrdHdr.Reset();
            OrdHdr.Setrange("Shopify Order ID",Recon."Shopify Order ID");
            OrdHdr.Setrange("Order Type",Recon."Shopify Order Type");
            If OrdHdr.FindSet() then
                If Not rec.Get(OrdHdr."BC Reference No.") then
                begin
                    Rec.init;
                    Rec."No." := OrdHdr."BC Reference No.";
                    Rec.Insert(False);
                end;    
        until Recon.next = 0;
        win.Close;
    End;
    procedure SetApplyType(Apply:integer)
    begin
        ApplyType := Apply;
    end;
    var
        ApplyType:Integer;
}
