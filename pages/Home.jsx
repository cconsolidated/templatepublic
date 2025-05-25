import Button from '../components/Button'

export default function Home() {
  return (
    <div className="container mx-auto p-4">
      <h1 className="text-3xl font-bold mb-4">Welcome to React Template</h1>
      <p className="mb-4">This is a simple React template with Vite and Tailwind CSS.</p>
      <Button onClick={() => alert('Button clicked!')}>
        Click me
      </Button>
    </div>
  )
} 