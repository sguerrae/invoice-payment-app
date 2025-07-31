import React from 'react';
import PropTypes from 'prop-types';
import { 
  Table, 
  TableHeader, 
  TableBody, 
  TableHead, 
  TableRow, 
  TableCell 
} from '../ui/table';
import { Badge } from '../ui/badge';
import { 
  DropdownMenu, 
  DropdownMenuTrigger, 
  DropdownMenuContent, 
  DropdownMenuItem 
} from '../ui/dropdown-menu';
import { Button } from '../ui/button';

export function InvoiceTable({ invoices, onGeneratePayment, onDownload }) {
  const formatCurrency = (amount) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'MXN'
    }).format(amount);
  };

  return (
    <div className="border rounded-lg shadow-sm bg-white overflow-x-auto">
      <Table className="w-full">
        <TableHeader className="bg-secondary/50">
          <TableRow className="hover:bg-transparent border-b">
            <TableHead className="font-semibold text-sm text-slate-700 py-3">Cliente</TableHead>
            <TableHead className="font-semibold text-sm text-slate-700 py-3 hidden sm:table-cell">Fecha</TableHead>
            <TableHead className="font-semibold text-sm text-slate-700 py-3 hidden md:table-cell">UUID</TableHead>
            <TableHead className="font-semibold text-sm text-slate-700 py-3 hidden sm:table-cell">Subtotal</TableHead>
            <TableHead className="font-semibold text-sm text-slate-700 py-3">Total</TableHead>
            <TableHead className="font-semibold text-sm text-slate-700 py-3">Estado</TableHead>
            <TableHead className="font-semibold text-sm text-slate-700 py-3">Acciones</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {invoices.length === 0 ? (
            <TableRow>
              <TableCell colSpan={7} className="text-center py-12 text-muted-foreground">
                <div className="flex flex-col items-center justify-center gap-2">
                  <p className="text-slate-500 font-medium">No se encontraron facturas</p>
                  <p className="text-sm text-slate-400">Sube archivos XML para verlos aquí.</p>
                </div>
              </TableCell>
            </TableRow>
          ) : (
            invoices.map((invoice) => (
              <TableRow key={invoice.id} className="hover:bg-secondary/30 border-b border-slate-200 transition-colors">
                <TableCell className="py-3 font-medium text-slate-800">{invoice.client}</TableCell>
                <TableCell className="py-3 text-slate-600 hidden sm:table-cell">{invoice.date}</TableCell>
                <TableCell className="py-3 font-mono text-xs text-slate-500 hidden md:table-cell">{invoice.uuid}</TableCell>
                <TableCell className="py-3 text-slate-600 hidden sm:table-cell">{formatCurrency(invoice.subtotal)}</TableCell>
                <TableCell className="py-3 font-medium text-slate-800">{formatCurrency(invoice.total)}</TableCell>
                <TableCell className="py-3">
                  <Badge variant={invoice.paid ? 'success' : 'warning'} className={`px-2 py-1 text-xs font-medium ${invoice.paid ? 'bg-green-100 text-green-800' : 'bg-yellow-100 text-amber-800'}`}>
                    {invoice.paid ? 'Pagado' : 'Pendiente'}
                  </Badge>
                </TableCell>
                <TableCell className="py-3">
                  <div className="flex flex-col gap-3">
                    <DropdownMenu>
                      <DropdownMenuTrigger asChild>
                        <Button 
                          variant="ghost" 
                          size="sm" 
                          className={`rounded-md border ${!invoice.paid ? 'border-blue-400 text-blue-600 hover:bg-blue-50' : 'border-blue-200 text-blue-500 hover:bg-blue-50'}`}
                        >
                          Acciones
                        </Button>
                      </DropdownMenuTrigger>
                      <DropdownMenuContent className="w-56 shadow-lg rounded-md border border-blue-200">
                        {!invoice.paid ? (
                          <DropdownMenuItem 
                            onClick={() => onGeneratePayment(invoice.id)}
                            className="cursor-pointer text-blue-700 font-medium"
                          >
                            Generar Complemento de Pago
                          </DropdownMenuItem>
                        ) : (
                          <>
                            <DropdownMenuItem 
                              onClick={() => onDownload(invoice.id, 'pdf')}
                              className="cursor-pointer text-blue-700"
                            >
                              Descargar PDF
                            </DropdownMenuItem>
                            <DropdownMenuItem 
                              onClick={() => onDownload(invoice.id, 'xml')}
                              className="cursor-pointer text-blue-700"
                            >
                              Descargar XML
                            </DropdownMenuItem>
                          </>
                        )}
                      </DropdownMenuContent>
                    </DropdownMenu>
                    <div className={`px-2 py-1.5 text-xs max-w-[220px] rounded ${
                           invoice.paid 
                             ? 'bg-green-50 border-l-2 border-l-green-400 text-green-700' 
                             : 'bg-amber-50 border-l-2 border-l-amber-400 text-amber-700'
                         }`}>
                      {invoice.paid
                        ? "El Complemento de Pago ya ha sido generado. Puedes descargar el PDF y XML correspondientes."
                        : "Esta factura no ha sido pagada. Puedes generar un Complemento de Pago si el cliente ya realizó el pago."}
                    </div>
                  </div>
                </TableCell>
              </TableRow>
            ))
          )}
        </TableBody>
      </Table>
    </div>
  );
}

InvoiceTable.propTypes = {
  invoices: PropTypes.arrayOf(
    PropTypes.shape({
      id: PropTypes.string.isRequired,
      client: PropTypes.string.isRequired,
      date: PropTypes.string.isRequired,
      uuid: PropTypes.string.isRequired,
      subtotal: PropTypes.number.isRequired,
      total: PropTypes.number.isRequired,
      paid: PropTypes.bool.isRequired,
    })
  ).isRequired,
  onGeneratePayment: PropTypes.func.isRequired,
  onDownload: PropTypes.func.isRequired,
};
