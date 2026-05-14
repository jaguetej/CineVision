import React from 'react'

export default function Footer() {
  return (
    <div>

        <footer class="py-5 bg-black">
            <div class="container px-5">
              <div className='row justify-content-evenly align-items-center'>
                <div className='col'>
                  <p className='m-1 lead text-center text-white'>En Cartelera</p>
                  <p className='m-1 lead text-center text-white'>Próximamente</p>
                  <p className='m-1 lead text-center text-white'>Cines</p>
                </div>
                <div className='col'>
                  <p className='m-1 lead text-center text-white'>E-Boleto</p>
                  <p className='m-1 lead text-center text-white'>Devoluciones</p>
                  <p className='m-1 lead text-center text-white'>Términos de Venta</p>
                </div>
              </div>
              <p class="mt-5 text-center text-white small">
                <strong>
                   Copyright &copy; CineVision 2022
                </strong> 
              </p>
            </div>
        </footer>

    </div>
  )
}
