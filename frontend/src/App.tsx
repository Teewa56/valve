import './App.css'
import { Layout } from '../app/layout'
import { LoginPage } from '../app/page'
import { DashboardPage } from '../app/dashboard/page'
import { ProviderPage } from '../app/provider/page'
import { BrowserRouter, Route, Routes } from 'react-router-dom'

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route element={<Layout />}>
          <Route path="/" element={<LoginPage />} />
          <Route path="/dashboard" element={<DashboardPage />} />
          <Route path="/provider" element={<ProviderPage />} />
          <Route path="*" element={<LoginPage />} />
        </Route>
      </Routes>
    </BrowserRouter>
  )
}
