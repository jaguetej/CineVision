import React from 'react'
import { Link } from 'react-router-dom'

export default function ErrorPage() {
  return (
    <div className='d-flex container justify-content-center align-items-center text-center' style={{height:"75vh"}}>

    <main>
        <h1>Lo sentimos, no encontramos la página que buscabas</h1>
        <h3>404 Página No Encontrada</h3>
        <div className='container mt-4'>
            <div className='col-sm-12 text-center'>
                <Link to="/">
                    <button className='btn btn-primary'>Volver al Inicio <i className="fa-solid fa-house"></i></button>
                </Link>
            </div>
        </div>
    </main>

</div>
  )
}
