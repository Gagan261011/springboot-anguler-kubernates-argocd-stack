import { Component, OnInit } from '@angular/core';
import { Employee, EmployeeService } from './employee.service';

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.css']
})
export class AppComponent implements OnInit {
  title = 'Employee Management';
  employees: Employee[] = [];
  selected: Employee = this.emptyEmployee();
  loading = false;
  error = '';

  constructor(private service: EmployeeService) {}

  ngOnInit(): void {
    this.load();
  }

  emptyEmployee(): Employee {
    return { id: undefined, name: '', department: '', salary: 0 };
  }

  load(): void {
    this.loading = true;
    this.service.getAll().subscribe({
      next: (data) => {
        this.employees = data;
        this.loading = false;
      },
      error: (err) => {
        this.error = err.message;
        this.loading = false;
      }
    });
  }

  edit(emp: Employee): void {
    this.selected = { ...emp };
  }

  save(): void {
    this.loading = true;
    const action = this.selected.id ? this.service.update(this.selected) : this.service.create(this.selected);
    action.subscribe({
      next: () => {
        this.selected = this.emptyEmployee();
        this.load();
      },
      error: (err) => {
        this.error = err.message;
        this.loading = false;
      }
    });
  }

  remove(emp: Employee): void {
    if (!emp.id) {
      return;
    }
    this.loading = true;
    this.service.delete(emp.id).subscribe({
      next: () => {
        this.load();
      },
      error: (err) => {
        this.error = err.message;
        this.loading = false;
      }
    });
  }

  cancel(): void {
    this.selected = this.emptyEmployee();
  }
}
